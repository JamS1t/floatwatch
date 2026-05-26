/// Model class for the `transactions` table.
///
/// All monetary values (amount, markup_earned) are in INTEGER centavos.
/// Markup settings are snapshotted at transaction creation time so historical
/// income calculations remain correct even if settings change later.
class TransactionModel {
  final int? id;
  final int storeId;
  final int dailyFloatId;

  /// 'cash_in' | 'cash_out' | 'bills_payment' | 'load_others'
  final String transactionType;

  /// Transaction amount in centavos
  final int amount;

  // Snapshot of markup settings at time of entry — never changes after insert
  final String markupRateTypeSnapshot; // 'percentage' | 'fixed' | 'per_bracket'
  final int markupRateValueSnapshot;
  final int? markupBracketSizeSnapshot;

  /// Markup income earned from this transaction, in centavos
  final int markupEarned;

  /// 1 if the owner manually overrode the calculated markup, 0 otherwise.
  /// Snapshot rate fields still reflect the configured rule at entry time.
  final int markupOverridden;

  final String? referenceNumber;
  final String? receiptImagePath; // local file path
  final String? receiptImageSyncUrl; // TODO: Firebase Storage URL after upload

  /// 'batch_ocr' | 'manual_owner' | 'manual_staff'
  final String entryMethod;

  /// 'owner' | 'staff'
  final String enteredByRole;

  final int? enteredByStaffId; // FK to staff table
  final String? missingReceiptReason;
  final double? ocrConfidenceScore; // 0.0–1.0
  final int oneTimePinUsed; // 1 if staff used a one-time PIN
  final int isFlagged; // 1 if manually flagged for review
  final String? flagReason;

  final String createdAt;
  final String updatedAt;
  final String syncId;

  const TransactionModel({
    this.id,
    required this.storeId,
    required this.dailyFloatId,
    required this.transactionType,
    required this.amount,
    required this.markupRateTypeSnapshot,
    required this.markupRateValueSnapshot,
    this.markupBracketSizeSnapshot,
    required this.markupEarned,
    this.markupOverridden = 0,
    this.referenceNumber,
    this.receiptImagePath,
    this.receiptImageSyncUrl,
    required this.entryMethod,
    required this.enteredByRole,
    this.enteredByStaffId,
    this.missingReceiptReason,
    this.ocrConfidenceScore,
    this.oneTimePinUsed = 0,
    this.isFlagged = 0,
    this.flagReason,
    required this.createdAt,
    required this.updatedAt,
    required this.syncId,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] as int?,
        storeId: map['store_id'] as int,
        dailyFloatId: map['daily_float_id'] as int,
        transactionType: map['transaction_type'] as String,
        amount: map['amount'] as int,
        markupRateTypeSnapshot: map['markup_rate_type_snapshot'] as String,
        markupRateValueSnapshot: map['markup_rate_value_snapshot'] as int,
        markupBracketSizeSnapshot: map['markup_bracket_size_snapshot'] as int?,
        markupEarned: map['markup_earned'] as int,
        markupOverridden: map['markup_overridden'] as int? ?? 0,
        referenceNumber: map['reference_number'] as String?,
        receiptImagePath: map['receipt_image_path'] as String?,
        receiptImageSyncUrl: map['receipt_image_sync_url'] as String?,
        entryMethod: map['entry_method'] as String,
        enteredByRole: map['entered_by_role'] as String,
        enteredByStaffId: map['entered_by_staff_id'] as int?,
        missingReceiptReason: map['missing_receipt_reason'] as String?,
        ocrConfidenceScore: map['ocr_confidence_score'] as double?,
        oneTimePinUsed: map['one_time_pin_used'] as int? ?? 0,
        isFlagged: map['is_flagged'] as int? ?? 0,
        flagReason: map['flag_reason'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncId: map['sync_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'store_id': storeId,
        'daily_float_id': dailyFloatId,
        'transaction_type': transactionType,
        'amount': amount,
        'markup_rate_type_snapshot': markupRateTypeSnapshot,
        'markup_rate_value_snapshot': markupRateValueSnapshot,
        'markup_bracket_size_snapshot': markupBracketSizeSnapshot,
        'markup_earned': markupEarned,
        'markup_overridden': markupOverridden,
        'reference_number': referenceNumber,
        'receipt_image_path': receiptImagePath,
        'receipt_image_sync_url': receiptImageSyncUrl,
        'entry_method': entryMethod,
        'entered_by_role': enteredByRole,
        'entered_by_staff_id': enteredByStaffId,
        'missing_receipt_reason': missingReceiptReason,
        'ocr_confidence_score': ocrConfidenceScore,
        'one_time_pin_used': oneTimePinUsed,
        'is_flagged': isFlagged,
        'flag_reason': flagReason,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_id': syncId,
      };

  TransactionModel copyWith({
    int? id,
    int? storeId,
    int? dailyFloatId,
    String? transactionType,
    int? amount,
    String? markupRateTypeSnapshot,
    int? markupRateValueSnapshot,
    int? markupBracketSizeSnapshot,
    int? markupEarned,
    int? markupOverridden,
    String? referenceNumber,
    String? receiptImagePath,
    String? receiptImageSyncUrl,
    String? entryMethod,
    String? enteredByRole,
    int? enteredByStaffId,
    String? missingReceiptReason,
    double? ocrConfidenceScore,
    int? oneTimePinUsed,
    int? isFlagged,
    String? flagReason,
    String? createdAt,
    String? updatedAt,
    String? syncId,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        storeId: storeId ?? this.storeId,
        dailyFloatId: dailyFloatId ?? this.dailyFloatId,
        transactionType: transactionType ?? this.transactionType,
        amount: amount ?? this.amount,
        markupRateTypeSnapshot:
            markupRateTypeSnapshot ?? this.markupRateTypeSnapshot,
        markupRateValueSnapshot:
            markupRateValueSnapshot ?? this.markupRateValueSnapshot,
        markupBracketSizeSnapshot:
            markupBracketSizeSnapshot ?? this.markupBracketSizeSnapshot,
        markupEarned: markupEarned ?? this.markupEarned,
        markupOverridden: markupOverridden ?? this.markupOverridden,
        referenceNumber: referenceNumber ?? this.referenceNumber,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
        receiptImageSyncUrl: receiptImageSyncUrl ?? this.receiptImageSyncUrl,
        entryMethod: entryMethod ?? this.entryMethod,
        enteredByRole: enteredByRole ?? this.enteredByRole,
        enteredByStaffId: enteredByStaffId ?? this.enteredByStaffId,
        missingReceiptReason: missingReceiptReason ?? this.missingReceiptReason,
        ocrConfidenceScore: ocrConfidenceScore ?? this.ocrConfidenceScore,
        oneTimePinUsed: oneTimePinUsed ?? this.oneTimePinUsed,
        isFlagged: isFlagged ?? this.isFlagged,
        flagReason: flagReason ?? this.flagReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncId: syncId ?? this.syncId,
      );

  bool get flagged => isFlagged == 1;
  bool get usedOtp => oneTimePinUsed == 1;
  bool get markupWasOverridden => markupOverridden == 1;
  bool get hasReceipt =>
      receiptImagePath != null && receiptImagePath!.isNotEmpty;

  @override
  String toString() =>
      'TransactionModel(id: $id, type: $transactionType, amount: $amount)';
}
