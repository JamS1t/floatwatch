import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../data/database/database_helper.dart';
import '../utils/date_formatter.dart';

/// Central security service for FloatWatch.
///
/// Checks store security_mode (simple | strict) and provides boolean flags
/// for every security-dependent feature. All PIN operations go through here.
///
/// Security modes:
///   simple — standard operation, minimal friction for solo owners
///   strict — full audit trail, PIN required for manual entries, owner
///             confirmation required for opening balance, etc.
class SecurityService {
  final DatabaseHelper _dbHelper;

  SecurityService(this._dbHelper);

  // ── PIN Hashing ───────────────────────────────────────────────────────────

  /// Hash a PIN using SHA-256. NEVER store raw PINs.
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a PIN against its stored SHA-256 hash.
  bool verifyPin(String inputPin, String storedHash) {
    return hashPin(inputPin) == storedHash;
  }

  // ── OTP Generation ────────────────────────────────────────────────────────

  /// Generate a cryptographically secure 6-digit one-time PIN.
  String generateOneTimePin() {
    final random = Random.secure();
    // Produces a 6-digit number: 100000–999999
    final pin = 100000 + random.nextInt(900000);
    return pin.toString();
  }

  /// Validate a one-time PIN for a staff member + purpose.
  ///
  /// Checks that:
  ///   - The hashed PIN matches a record in one_time_pins
  ///   - The record is for the given staffId and purpose
  ///   - The record has not been used
  ///   - The record has not expired
  ///
  /// If valid, marks the OTP as used.
  Future<bool> validateOneTimePin(
    String pin,
    int staffId,
    String purpose,
  ) async {
    final db = await _dbHelper.database;
    final pinHash = hashPin(pin);
    final now = DateFormatter.nowDb();

    final result = await db.query(
      'one_time_pins',
      where: 'staff_id = ? AND purpose = ? AND is_used = 0 AND expires_at > ? AND pin_hash = ?',
      whereArgs: [staffId, purpose, now, pinHash],
      limit: 1,
    );

    if (result.isEmpty) return false;

    // Mark as used so it cannot be reused
    await db.update(
      'one_time_pins',
      {'is_used': 1},
      where: 'id = ?',
      whereArgs: [result.first['id']],
    );
    return true;
  }

  // ── Security Mode Checks ──────────────────────────────────────────────────

  /// Fetch the security mode for a store.
  Future<String> _getSecurityMode(int storeId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stores',
      columns: ['security_mode'],
      where: 'id = ?',
      whereArgs: [storeId],
      limit: 1,
    );
    if (result.isEmpty) return 'simple';
    return result.first['security_mode'] as String? ?? 'simple';
  }

  /// Returns true if the store is in strict security mode.
  Future<bool> isStrictMode(int storeId) async =>
      (await _getSecurityMode(storeId)) == 'strict';

  /// Returns true if manual transaction entry requires a one-time PIN.
  /// In strict mode: YES. In simple mode: NO.
  Future<bool> requiresManualEntryPin(int storeId) async =>
      isStrictMode(storeId);

  /// Returns true if opening balance requires owner confirmation.
  /// In strict mode: YES (staff sets opening balance → owner confirms).
  Future<bool> requiresOpeningBalanceConfirmation(int storeId) async =>
      isStrictMode(storeId);

  /// Returns true if staff must submit transactions before day can be closed.
  /// In strict mode: YES. In simple mode: NO.
  Future<bool> requiresStaffDaySubmission(int storeId) async =>
      isStrictMode(storeId);
}
