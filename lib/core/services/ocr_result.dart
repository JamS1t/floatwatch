/// Parsed data extracted from a single GCash receipt via OCR.
class OcrResult {
  final String imagePath;
  final String rawText;
  final String? transactionType; // cash_in | cash_out | bills_payment | load_others
  final int? amountCentavos;
  final String? referenceNumber;
  final DateTime? transactionDateTime;
  final String? recipientNumber; // 09XXXXXXXXX format
  final String? senderNumber; // 09XXXXXXXXX format
  final double confidence; // 0.0–1.0
  final bool needsManualReview;
  final String? reviewReason;

  const OcrResult({
    required this.imagePath,
    required this.rawText,
    this.transactionType,
    this.amountCentavos,
    this.referenceNumber,
    this.transactionDateTime,
    this.recipientNumber,
    this.senderNumber,
    this.confidence = 0.0,
    this.needsManualReview = true,
    this.reviewReason,
  });

  OcrResult copyWith({
    String? imagePath,
    String? rawText,
    String? transactionType,
    int? amountCentavos,
    String? referenceNumber,
    DateTime? transactionDateTime,
    String? recipientNumber,
    String? senderNumber,
    double? confidence,
    bool? needsManualReview,
    String? reviewReason,
  }) =>
      OcrResult(
        imagePath: imagePath ?? this.imagePath,
        rawText: rawText ?? this.rawText,
        transactionType: transactionType ?? this.transactionType,
        amountCentavos: amountCentavos ?? this.amountCentavos,
        referenceNumber: referenceNumber ?? this.referenceNumber,
        transactionDateTime: transactionDateTime ?? this.transactionDateTime,
        recipientNumber: recipientNumber ?? this.recipientNumber,
        senderNumber: senderNumber ?? this.senderNumber,
        confidence: confidence ?? this.confidence,
        needsManualReview: needsManualReview ?? this.needsManualReview,
        reviewReason: reviewReason ?? this.reviewReason,
      );

  @override
  String toString() =>
      'OcrResult(type: $transactionType, amount: $amountCentavos, '
      'confidence: ${confidence.toStringAsFixed(2)}, review: $needsManualReview)';
}
