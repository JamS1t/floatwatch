import 'package:flutter/material.dart';

/// Centralized color constants for FloatWatch.
/// Always use these — never hardcode hex values in widget files.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B4FD8); // Trust, professional blue
  static const Color secondary = Color(0xFF16A34A); // Money green
  static const Color warning = Color(0xFFF59E0B); // Caution yellow
  static const Color danger = Color(0xFFDC2626); // Alert red

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFCBD5E1);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFFADB5C5);
  static const Color textOnPrimary = Colors.white;

  // ── Status (discrepancy + report status) ─────────────────────────────────
  // GREEN  = clean, abs(discrepancy) ≤ ₱10
  // YELLOW = warning, ₱10 < abs(discrepancy) ≤ ₱200
  // RED    = flagged, abs(discrepancy) > ₱200
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusYellow = Color(0xFFF59E0B);
  static const Color statusRed = Color(0xFFDC2626);

  // ── Light tint variants ───────────────────────────────────────────────────
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color secondaryLight = Color(0xFFDCFCE7);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color statusGreenLight = Color(0xFFDCFCE7);
  static const Color statusYellowLight = Color(0xFFFEF3C7);
  static const Color statusRedLight = Color(0xFFFEE2E2);

  // ── Transaction type colors ───────────────────────────────────────────────
  static const Color cashIn = Color(0xFF16A34A);
  static const Color cashOut = Color(0xFF1B4FD8);
  static const Color billsPayment = Color(0xFF9333EA);
  static const Color loadOthers = Color(0xFFF59E0B);

  // ── Overlay ───────────────────────────────────────────────────────────────
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x40FFFFFF);

  /// Returns the background color for a given discrepancy status string.
  static Color statusBackground(String status) {
    switch (status) {
      case 'clean':
        return statusGreenLight;
      case 'warning':
        return statusYellowLight;
      case 'flagged':
        return statusRedLight;
      default:
        return background;
    }
  }

  /// Returns the foreground color for a given discrepancy status string.
  static Color statusForeground(String status) {
    switch (status) {
      case 'clean':
        return statusGreen;
      case 'warning':
        return statusYellow;
      case 'flagged':
        return statusRed;
      default:
        return textSecondary;
    }
  }

  /// Returns the color associated with a transaction type.
  static Color transactionTypeColor(String type) {
    switch (type) {
      case 'cash_in':
        return cashIn;
      case 'cash_out':
        return cashOut;
      case 'bills_payment':
        return billsPayment;
      case 'load_others':
        return loadOthers;
      default:
        return textSecondary;
    }
  }
}
