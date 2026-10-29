import 'package:flutter/material.dart';

/// Teal Mint design system color tokens.
///
/// Brand and semantic colors come from the final design system.
/// Colors marked "added" are neutrals and soft tints that the palette
/// did not define but the UI needs (body text, borders, status backgrounds).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF14B8A6); // Teal Mint
  static const Color primaryDark = Color(0xFF0F766E); // Headings, active states
  static const Color mint = Color(0xFF14B8A6); // Mint alias
  static const Color teal = Color(0xFF0F766E); // Teal alias
  static const Color brightTeal = Color(0xFF17C3B2); // 3D button gradient top
  static const Color deepTeal = Color(0xFF084B45); // 3D button bevel base
  static const Color paleMint = Color(0xFFCCFBF1); // Soft teal mint surface
  static const Color bg = Color(0xFFF0FDFA); // Background alias
  static const Color ink = Color(0xFF0F2A29); // Primary text alias
  static const Color muted = Color(0xFF527270); // Secondary text alias
  static const Color red = Color(0xFFDC2626); // Alert red alias
  static const Color green = Color(0xFF16A34A); // Success green alias

  // Surfaces
  static const Color background = Color(0xFFF0FDFA); // Main screen backgrounds
  static const Color surface = Color(0xFFFFFFFF); // Cards and forms

  // Semantic
  static const Color success = Color(0xFF16A34A); // Payments received, success
  static const Color error = Color(0xFFDC2626); // Pending alerts, errors

  // Added: text on primary. White on #14B8A6 is about 2.5:1 contrast,
  // so filled primary buttons use this dark teal instead.
  static const Color onPrimary = Color(0xFF042F2E);

  // Added: neutrals
  static const Color textPrimary = Color(0xFF0F2A29);
  static const Color textSecondary = Color(0xFF527270);
  static const Color textDisabled = Color(0xFF9DB5B3);
  static const Color border = Color(0xFFCDE9E5);
  static const Color divider = Color(0xFFDDF0ED);

  // Added: soft tints for status chips and banners
  static const Color primarySurface = Color(0xFFCCFBF1); // Soft teal mint surface
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color errorSoft = Color(0xFFFEE2E2);
}
