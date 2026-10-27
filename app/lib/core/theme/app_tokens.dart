import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing scale (4pt grid).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Default horizontal padding for screens.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: 16);
}

/// Corner radii. Rounded rectangles only, no stadium or pill shapes.
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
}

/// Text styles. Fallback fonts keep Gujarati and Hindi legible when the
/// system font lacks those scripts. Add the Noto fonts to pubspec.yaml,
/// or swap in google_fonts if you prefer.
class AppText {
  AppText._();

  static const List<String> _fallback = [
    'Noto Sans Gujarati',
    'Noto Sans Devanagari',
  ];

  static const TextStyle _base = TextStyle(
    fontFamilyFallback: _fallback,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Headings use dark teal
  static final TextStyle h1 = _base.copyWith(
    fontSize: 28,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );
  static final TextStyle h2 = _base.copyWith(
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );
  static final TextStyle h3 = _base.copyWith(
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
  );

  // Body
  static final TextStyle bodyLarge = _base.copyWith(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle body = _base.copyWith(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle caption = _base.copyWith(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Labels and buttons
  static final TextStyle label = _base.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle button = _base.copyWith(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  // Money. Tabular figures keep amounts aligned in lists and ledgers.
  static final TextStyle amount = _base.copyWith(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final TextStyle amountLarge = _base.copyWith(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final TextStyle amountReceived =
      amount.copyWith(color: AppColors.success);
  static final TextStyle amountPending =
      amount.copyWith(color: AppColors.error);
}
