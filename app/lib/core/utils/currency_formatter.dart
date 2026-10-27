import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Converts paise (integer) to formatted Rupee string: e.g. 50000 -> ₹500.00
  static String formatPaise(int paise, {bool hideZeroDecimals = false}) {
    final double rupees = paise / 100.0;
    if (hideZeroDecimals && paise % 100 == 0) {
      return _compactFormatter.format(rupees);
    }
    return _formatter.format(rupees);
  }

  /// Converts Rupees (double) to paise (integer)
  static int toPaise(double rupees) {
    return (rupees * 100).round();
  }
}

