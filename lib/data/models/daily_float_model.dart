/// Model class for the `daily_float` table.
///
/// Tracks the opening/closing GCash and cash balances for one store on one day.
/// All balance fields are in INTEGER centavos.
///
/// Status values: 'open' | 'clean' | 'warning' | 'flagged'
class DailyFloatModel {
  final int? id;
  final int storeId;
  final String date; // DB date string: yyyy-MM-dd

  // Opening balances (set at start of day)
  final int? openingGcashBalance; // centavos
  final int? openingCash; // centavos

  // Closing balances (set at end of day)
  final int? closingGcashBalance; // centavos
  final int? closingCash; // centavos

  // Calculated expected balances
  final int? expectedGcashBalance; // centavos
  final int? expectedCash; // centavos

  // Discrepancy = closing - expected (negative means short)
  final int? discrepancyGcash; // centavos
  final int? discrepancyCash; // centavos

  /// 'open' | 'clean' | 'warning' | 'flagged'
  final String status;

  final int isClosed; // 1 = day is closed
  final String? openingSetBy; // 'owner' | 'staff'
  final int openingConfirmed; // 1 = owner confirmed the opening balance

  final String createdAt;
  final String updatedAt;
  final String syncId;

  const DailyFloatModel({
    this.id,
    required this.storeId,
    required this.date,
    this.openingGcashBalance,
    this.openingCash,
    this.closingGcashBalance,
    this.closingCash,
    this.expectedGcashBalance,
    this.expectedCash,
    this.discrepancyGcash,
    this.discrepancyCash,
    this.status = 'open',
    this.isClosed = 0,
    this.openingSetBy,
    this.openingConfirmed = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.syncId,
  });

  factory DailyFloatModel.fromMap(Map<String, dynamic> map) => DailyFloatModel(
        id: map['id'] as int?,
        storeId: map['store_id'] as int,
        date: map['date'] as String,
        openingGcashBalance: map['opening_gcash_balance'] as int?,
        openingCash: map['opening_cash'] as int?,
        closingGcashBalance: map['closing_gcash_balance'] as int?,
        closingCash: map['closing_cash'] as int?,
        expectedGcashBalance: map['expected_gcash_balance'] as int?,
        expectedCash: map['expected_cash'] as int?,
        discrepancyGcash: map['discrepancy_gcash'] as int?,
        discrepancyCash: map['discrepancy_cash'] as int?,
        status: map['status'] as String? ?? 'open',
        isClosed: map['is_closed'] as int? ?? 0,
        openingSetBy: map['opening_set_by'] as String?,
        openingConfirmed: map['opening_confirmed'] as int? ?? 0,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncId: map['sync_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'store_id': storeId,
        'date': date,
        'opening_gcash_balance': openingGcashBalance,
        'opening_cash': openingCash,
        'closing_gcash_balance': closingGcashBalance,
        'closing_cash': closingCash,
        'expected_gcash_balance': expectedGcashBalance,
        'expected_cash': expectedCash,
        'discrepancy_gcash': discrepancyGcash,
        'discrepancy_cash': discrepancyCash,
        'status': status,
        'is_closed': isClosed,
        'opening_set_by': openingSetBy,
        'opening_confirmed': openingConfirmed,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_id': syncId,
      };

  DailyFloatModel copyWith({
    int? id,
    int? storeId,
    String? date,
    int? openingGcashBalance,
    int? openingCash,
    int? closingGcashBalance,
    int? closingCash,
    int? expectedGcashBalance,
    int? expectedCash,
    int? discrepancyGcash,
    int? discrepancyCash,
    String? status,
    int? isClosed,
    String? openingSetBy,
    int? openingConfirmed,
    String? createdAt,
    String? updatedAt,
    String? syncId,
  }) =>
      DailyFloatModel(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        date: date ?? this.date,
        openingGcashBalance: openingGcashBalance ?? this.openingGcashBalance,
        openingCash: openingCash ?? this.openingCash,
        closingGcashBalance: closingGcashBalance ?? this.closingGcashBalance,
        closingCash: closingCash ?? this.closingCash,
        expectedGcashBalance: expectedGcashBalance ?? this.expectedGcashBalance,
        expectedCash: expectedCash ?? this.expectedCash,
        discrepancyGcash: discrepancyGcash ?? this.discrepancyGcash,
        discrepancyCash: discrepancyCash ?? this.discrepancyCash,
        status: status ?? this.status,
        isClosed: isClosed ?? this.isClosed,
        openingSetBy: openingSetBy ?? this.openingSetBy,
        openingConfirmed: openingConfirmed ?? this.openingConfirmed,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncId: syncId ?? this.syncId,
      );

  bool get closed => isClosed == 1;
  bool get confirmed => openingConfirmed == 1;
  bool get isOpen => status == 'open';
  bool get isClean => status == 'clean';
  bool get isWarning => status == 'warning';
  bool get isFlagged => status == 'flagged';
  bool get isAutoClosed => status == 'auto_closed';

  @override
  String toString() => 'DailyFloatModel(id: $id, date: $date, status: $status)';
}
