import 'package:intl/intl.dart';

/// Handles all Philippine Peso formatting for FloatWatch.
///
/// IMPORTANT: All monetary values are stored as INTEGER centavos in the
/// database. This class converts between centavos and display strings.
/// Never store or compute with raw doubles — only convert at the UI layer.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _pesos = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 2,
    locale: 'en_PH',
  );

  static final NumberFormat _pesosNoDecimal = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 0,
    locale: 'en_PH',
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    symbol: '₱',
    locale: 'en_PH',
  );

  // ── Display ───────────────────────────────────────────────────────────────

  /// Format centavos to full peso string: ₱1,000.00
  static String format(int centavos) => _pesos.format(centavos / 100.0);

  /// Format centavos without decimal places: ₱1,000
  static String formatNoDecimal(int centavos) =>
      _pesosNoDecimal.format(centavos / 100.0);

  /// Format centavos to compact string: ₱1K, ₱2.5M
  static String formatCompact(int centavos) =>
      _compact.format(centavos / 100.0);

  /// Format a raw peso double (from user input) for display.
  static String formatPesos(double pesos) => _pesos.format(pesos);

  // ── Parsing ───────────────────────────────────────────────────────────────

  /// Parse a peso input string (e.g. "1,234.50" or "₱1,234.50") to centavos.
  /// Returns 0 if the input cannot be parsed.
  static int parseToCentavos(String pesoInput) {
    final cleaned = pesoInput.replaceAll(RegExp(r'[₱,\s]'), '');
    final pesos = double.tryParse(cleaned) ?? 0.0;
    return toCentavos(pesos);
  }

  // ── Conversion ────────────────────────────────────────────────────────────

  /// Convert double pesos to integer centavos (rounded).
  static int toCentavos(double pesos) => (pesos * 100).round();

  /// Convert integer centavos to double pesos.
  static double toPesos(int centavos) => centavos / 100.0;

  // ── Sign helpers ──────────────────────────────────────────────────────────

  /// Returns a signed string e.g. "+₱500.00" or "-₱200.00"
  static String formatSigned(int centavos) {
    final sign = centavos >= 0 ? '+' : '';
    return '$sign${format(centavos)}';
  }

  /// Returns the absolute value formatted as peso string.
  static String formatAbs(int centavos) => format(centavos.abs());
}
