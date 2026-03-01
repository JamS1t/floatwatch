/// Model class for the `markup_settings` table.
///
/// Rate storage conventions:
///   percentage  → rate_value = percentage × 100 (e.g. 1.00% = 100)
///   fixed       → rate_value = flat fee in centavos (e.g. ₱10 = 1000)
///   per_bracket → rate_value = fee per bracket in centavos;
///                 bracket_size = bracket size in centavos
class MarkupSettingsModel {
  final int? id;
  final int storeId;

  /// 'cash_in' | 'cash_out' | 'bills_payment' | 'load_others'
  final String transactionType;

  /// 'percentage' | 'fixed' | 'per_bracket'
  final String rateType;

  /// See class-level documentation for storage conventions.
  final int rateValue;

  /// Only used when rateType = 'per_bracket'. Stored in centavos.
  final int? bracketSize;

  final String effectiveDate; // DB date string
  final String createdAt;
  final String syncId;

  const MarkupSettingsModel({
    this.id,
    required this.storeId,
    required this.transactionType,
    required this.rateType,
    required this.rateValue,
    this.bracketSize,
    required this.effectiveDate,
    required this.createdAt,
    required this.syncId,
  });

  factory MarkupSettingsModel.fromMap(Map<String, dynamic> map) =>
      MarkupSettingsModel(
        id: map['id'] as int?,
        storeId: map['store_id'] as int,
        transactionType: map['transaction_type'] as String,
        rateType: map['rate_type'] as String,
        rateValue: map['rate_value'] as int,
        bracketSize: map['bracket_size'] as int?,
        effectiveDate: map['effective_date'] as String,
        createdAt: map['created_at'] as String,
        syncId: map['sync_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'store_id': storeId,
        'transaction_type': transactionType,
        'rate_type': rateType,
        'rate_value': rateValue,
        'bracket_size': bracketSize,
        'effective_date': effectiveDate,
        'created_at': createdAt,
        'sync_id': syncId,
      };

  MarkupSettingsModel copyWith({
    int? id,
    int? storeId,
    String? transactionType,
    String? rateType,
    int? rateValue,
    int? bracketSize,
    String? effectiveDate,
    String? createdAt,
    String? syncId,
  }) =>
      MarkupSettingsModel(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        transactionType: transactionType ?? this.transactionType,
        rateType: rateType ?? this.rateType,
        rateValue: rateValue ?? this.rateValue,
        bracketSize: bracketSize ?? this.bracketSize,
        effectiveDate: effectiveDate ?? this.effectiveDate,
        createdAt: createdAt ?? this.createdAt,
        syncId: syncId ?? this.syncId,
      );

  @override
  String toString() =>
      'MarkupSettingsModel(txType: $transactionType, rateType: $rateType, rateValue: $rateValue)';
}
