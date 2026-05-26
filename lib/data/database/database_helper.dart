import 'package:path/path.dart' as path_pkg;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

/// Singleton database helper for FloatWatch.
///
/// All SQLite operations pass through this class.
/// UI → Provider (ViewModel) → Repository → DatabaseHelper → SQLite
///
/// Database version: 1
/// Use onUpgrade() for future schema migrations — never drop tables.
class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  /// The single shared instance.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Lazily initialise and return the database.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath =
        path_pkg.join(dbPath, AppConstants.databaseName);

    return openDatabase(
      fullPath,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Enforce foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE owners ADD COLUMN gcash_number TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN markup_overridden INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // ── Table creation ────────────────────────────────────────────────────────

  Future<void> _createAllTables(Database db) async {
    // Run all CREATE TABLE statements in a single batch for speed.
    final batch = db.batch();

    // ── owners ────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS owners (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        mobile_number   TEXT    NOT NULL,
        gcash_number    TEXT    NOT NULL DEFAULT '',
        pin_hash        TEXT    NOT NULL,
        store_mode      TEXT    DEFAULT 'solo',
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL,
        sync_id         TEXT    NOT NULL UNIQUE
      )
    ''');

    // ── stores ────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS stores (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id              INTEGER NOT NULL,
        store_name            TEXT    NOT NULL,
        location              TEXT,
        gcash_outlet_number   TEXT,
        security_mode         TEXT    DEFAULT 'simple',
        is_active             INTEGER DEFAULT 1,
        created_at            TEXT    NOT NULL,
        updated_at            TEXT    NOT NULL,
        sync_id               TEXT    NOT NULL UNIQUE,
        FOREIGN KEY (owner_id) REFERENCES owners(id)
      )
    ''');

    // ── staff ─────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS staff (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id        INTEGER NOT NULL,
        store_id        INTEGER NOT NULL,
        name            TEXT    NOT NULL,
        mobile_number   TEXT,
        pin_hash        TEXT    NOT NULL,
        is_active       INTEGER DEFAULT 1,
        is_locked       INTEGER DEFAULT 0,
        failed_attempts INTEGER DEFAULT 0,
        last_active     TEXT,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL,
        sync_id         TEXT    NOT NULL UNIQUE,
        FOREIGN KEY (owner_id) REFERENCES owners(id),
        FOREIGN KEY (store_id) REFERENCES stores(id)
      )
    ''');

    // ── markup_settings ───────────────────────────────────────────────────
    // rate_value for 'percentage' = percentage × 100 (e.g. 1% → 100)
    // rate_value for 'fixed'      = flat fee in centavos
    // rate_value for 'per_bracket'= fee per bracket in centavos
    batch.execute('''
      CREATE TABLE IF NOT EXISTS markup_settings (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id          INTEGER NOT NULL,
        transaction_type  TEXT    NOT NULL,
        rate_type         TEXT    NOT NULL,
        rate_value        INTEGER NOT NULL,
        bracket_size      INTEGER,
        effective_date    TEXT    NOT NULL,
        created_at        TEXT    NOT NULL,
        sync_id           TEXT    NOT NULL UNIQUE,
        FOREIGN KEY (store_id) REFERENCES stores(id)
      )
    ''');

    // ── daily_float ───────────────────────────────────────────────────────
    // All balance fields are in centavos.
    // UNIQUE(store_id, date) ensures one float record per store per day.
    batch.execute('''
      CREATE TABLE IF NOT EXISTS daily_float (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id                INTEGER NOT NULL,
        date                    TEXT    NOT NULL,
        opening_gcash_balance   INTEGER,
        opening_cash            INTEGER,
        closing_gcash_balance   INTEGER,
        closing_cash            INTEGER,
        expected_gcash_balance  INTEGER,
        expected_cash           INTEGER,
        discrepancy_gcash       INTEGER,
        discrepancy_cash        INTEGER,
        status                  TEXT    DEFAULT 'open',
        is_closed               INTEGER DEFAULT 0,
        opening_set_by          TEXT,
        opening_confirmed       INTEGER DEFAULT 0,
        created_at              TEXT    NOT NULL,
        updated_at              TEXT    NOT NULL,
        sync_id                 TEXT    NOT NULL UNIQUE,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        UNIQUE(store_id, date)
      )
    ''');

    // ── transactions ──────────────────────────────────────────────────────
    // Snapshots of markup settings are stored alongside each transaction so
    // historical income is always accurate even if settings change later.
    batch.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id                            INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id                      INTEGER NOT NULL,
        daily_float_id                INTEGER NOT NULL,
        transaction_type              TEXT    NOT NULL,
        amount                        INTEGER NOT NULL,
        markup_rate_type_snapshot     TEXT    NOT NULL,
        markup_rate_value_snapshot    INTEGER NOT NULL,
        markup_bracket_size_snapshot  INTEGER,
        markup_earned                 INTEGER NOT NULL,
        reference_number              TEXT,
        receipt_image_path            TEXT,
        receipt_image_sync_url        TEXT,
        entry_method                  TEXT    NOT NULL,
        entered_by_role               TEXT    NOT NULL,
        entered_by_staff_id           INTEGER,
        missing_receipt_reason        TEXT,
        ocr_confidence_score          REAL,
        one_time_pin_used             INTEGER DEFAULT 0,
        is_flagged                    INTEGER DEFAULT 0,
        flag_reason                   TEXT,
        markup_overridden             INTEGER NOT NULL DEFAULT 0,
        created_at                    TEXT    NOT NULL,
        updated_at                    TEXT    NOT NULL,
        sync_id                       TEXT    NOT NULL UNIQUE,
        FOREIGN KEY (store_id)            REFERENCES stores(id),
        FOREIGN KEY (daily_float_id)      REFERENCES daily_float(id),
        FOREIGN KEY (entered_by_staff_id) REFERENCES staff(id)
      )
    ''');

    // ── daily_reports ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS daily_reports (
        id                        INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id                  INTEGER NOT NULL,
        daily_float_id            INTEGER NOT NULL,
        date                      TEXT    NOT NULL,
        total_transactions        INTEGER DEFAULT 0,
        total_cash_in_count       INTEGER DEFAULT 0,
        total_cash_out_count      INTEGER DEFAULT 0,
        total_bills_payment_count INTEGER DEFAULT 0,
        total_load_others_count   INTEGER DEFAULT 0,
        total_gross_amount        INTEGER DEFAULT 0,
        total_markup_earned       INTEGER DEFAULT 0,
        status                    TEXT,
        notes                     TEXT,
        closed_by                 TEXT,
        created_at                TEXT    NOT NULL,
        sync_id                   TEXT    NOT NULL UNIQUE,
        FOREIGN KEY (store_id)       REFERENCES stores(id),
        FOREIGN KEY (daily_float_id) REFERENCES daily_float(id)
      )
    ''');

    // ── one_time_pins ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS one_time_pins (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id    INTEGER NOT NULL,
        staff_id    INTEGER NOT NULL,
        pin_hash    TEXT    NOT NULL,
        purpose     TEXT    NOT NULL,
        is_used     INTEGER DEFAULT 0,
        expires_at  TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        sync_id     TEXT    NOT NULL UNIQUE,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        FOREIGN KEY (staff_id) REFERENCES staff(id)
      )
    ''');

    // ── sync_log ──────────────────────────────────────────────────────────
    // Every write to any other table must also write a row here.
    // TODO: Firebase sync will read un-synced rows and mark them synced.
    batch.execute('''
      CREATE TABLE IF NOT EXISTS sync_log (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name      TEXT    NOT NULL,
        record_sync_id  TEXT    NOT NULL,
        action          TEXT    NOT NULL,
        is_synced       INTEGER DEFAULT 0,
        synced_at       TEXT,
        created_at      TEXT    NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Delete the database (development / testing only).
  Future<void> deleteDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_pkg.join(dbPath, AppConstants.databaseName);
    await deleteDatabase(fullPath);
    _database = null;
  }
}
