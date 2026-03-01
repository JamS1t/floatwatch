/// Model class for the `daily_reports` table.
///
/// A daily report is created when the owner closes the day.
/// All monetary totals are in INTEGER centavos.
class DailyReportModel {
  final int? id;
  final int storeId;
  final int dailyFloatId;
  final String date; // DB date string: yyyy-MM-dd

  final int totalTransactions;
  final int totalCashInCount;
  final int totalCashOutCount;
  final int totalBillsPaymentCount;
  final int totalLoadOthersCount;

  /// Sum of all transaction amounts in centavos
  final int totalGrossAmount;

  /// Sum of all markup_earned in centavos — the store's actual income
  final int totalMarkupEarned;

  /// 'clean' | 'warning' | 'flagged'
  final String? status;

  final String? notes;
  final String? closedBy; // always 'owner'

  final String createdAt;
  final String syncId;

  const DailyReportModel({
    this.id,
    required this.storeId,
    required this.dailyFloatId,
    required this.date,
    this.totalTransactions = 0,
    this.totalCashInCount = 0,
    this.totalCashOutCount = 0,
    this.totalBillsPaymentCount = 0,
    this.totalLoadOthersCount = 0,
    this.totalGrossAmount = 0,
    this.totalMarkupEarned = 0,
    this.status,
    this.notes,
    this.closedBy,
    required this.createdAt,
    required this.syncId,
  });

  factory DailyReportModel.fromMap(Map<String, dynamic> map) => DailyReportModel(
        id: map['id'] as int?,
        storeId: map['store_id'] as int,
        dailyFloatId: map['daily_float_id'] as int,
        date: map['date'] as String,
        totalTransactions: map['total_transactions'] as int? ?? 0,
        totalCashInCount: map['total_cash_in_count'] as int? ?? 0,
        totalCashOutCount: map['total_cash_out_count'] as int? ?? 0,
        totalBillsPaymentCount: map['total_bills_payment_count'] as int? ?? 0,
        totalLoadOthersCount: map['total_load_others_count'] as int? ?? 0,
        totalGrossAmount: map['total_gross_amount'] as int? ?? 0,
        totalMarkupEarned: map['total_markup_earned'] as int? ?? 0,
        status: map['status'] as String?,
        notes: map['notes'] as String?,
        closedBy: map['closed_by'] as String?,
        createdAt: map['created_at'] as String,
        syncId: map['sync_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'store_id': storeId,
        'daily_float_id': dailyFloatId,
        'date': date,
        'total_transactions': totalTransactions,
        'total_cash_in_count': totalCashInCount,
        'total_cash_out_count': totalCashOutCount,
        'total_bills_payment_count': totalBillsPaymentCount,
        'total_load_others_count': totalLoadOthersCount,
        'total_gross_amount': totalGrossAmount,
        'total_markup_earned': totalMarkupEarned,
        'status': status,
        'notes': notes,
        'closed_by': closedBy,
        'created_at': createdAt,
        'sync_id': syncId,
      };

  DailyReportModel copyWith({
    int? id,
    int? storeId,
    int? dailyFloatId,
    String? date,
    int? totalTransactions,
    int? totalCashInCount,
    int? totalCashOutCount,
    int? totalBillsPaymentCount,
    int? totalLoadOthersCount,
    int? totalGrossAmount,
    int? totalMarkupEarned,
    String? status,
    String? notes,
    String? closedBy,
    String? createdAt,
    String? syncId,
  }) =>
      DailyReportModel(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        dailyFloatId: dailyFloatId ?? this.dailyFloatId,
        date: date ?? this.date,
        totalTransactions: totalTransactions ?? this.totalTransactions,
        totalCashInCount: totalCashInCount ?? this.totalCashInCount,
        totalCashOutCount: totalCashOutCount ?? this.totalCashOutCount,
        totalBillsPaymentCount:
            totalBillsPaymentCount ?? this.totalBillsPaymentCount,
        totalLoadOthersCount: totalLoadOthersCount ?? this.totalLoadOthersCount,
        totalGrossAmount: totalGrossAmount ?? this.totalGrossAmount,
        totalMarkupEarned: totalMarkupEarned ?? this.totalMarkupEarned,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        closedBy: closedBy ?? this.closedBy,
        createdAt: createdAt ?? this.createdAt,
        syncId: syncId ?? this.syncId,
      );

  @override
  String toString() =>
      'DailyReportModel(id: $id, date: $date, markupEarned: $totalMarkupEarned)';
}
