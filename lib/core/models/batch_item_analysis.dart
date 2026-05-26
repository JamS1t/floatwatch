/// Status of a single item in a batch analysis.
enum BatchItemStatus {
  /// Ready to save — no issues detected.
  ready,

  /// Duplicate of an existing transaction in the DB.
  duplicate,

  /// Receipt date differs from today — target day is still open.
  crossDate,

  /// Receipt date differs from today — target day is closed.
  crossDateClosed,
}

/// Per-item analysis result for OCR batch dedup & cross-date checks.
class BatchItemAnalysis {
  final int index;
  final BatchItemStatus status;

  /// Receipt date in yyyy-MM-dd format (null if same as today or no date).
  final String? receiptDate;

  /// ID of the existing transaction if this is a duplicate.
  final int? existingTxId;

  /// Whether the target day's daily_float is closed.
  final bool dayIsClosed;

  const BatchItemAnalysis({
    required this.index,
    required this.status,
    this.receiptDate,
    this.existingTxId,
    this.dayIsClosed = false,
  });

  @override
  String toString() =>
      'BatchItemAnalysis(index: $index, status: $status, date: $receiptDate)';
}
