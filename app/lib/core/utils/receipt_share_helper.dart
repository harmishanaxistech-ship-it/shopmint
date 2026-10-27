import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/bill_model.dart';
import 'currency_formatter.dart';

class ReceiptShareHelper {
  static String generateReceiptText(BillModel bill, {String shopName = 'ShopMint Store'}) {
    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('  $shopName');
    buffer.writeln('  Bill No: ${bill.billNo}');
    buffer.writeln('  Date: ${_formatDate(bill.createdAt)}');
    buffer.writeln('  Customer: ${bill.customerName}');
    buffer.writeln('================================');
    buffer.writeln('ITEMS:');

    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      final qtyStr = item.qty % 1 == 0 ? item.qty.toInt().toString() : item.qty.toStringAsFixed(2);
      final rateStr = CurrencyFormatter.formatPaise(item.rate, hideZeroDecimals: true);
      final amtStr = CurrencyFormatter.formatPaise(item.amount, hideZeroDecimals: true);
      buffer.writeln('${i + 1}. ${item.name}');
      buffer.writeln('   $qtyStr ${item.unit} x $rateStr = $amtStr');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ${CurrencyFormatter.formatPaise(bill.subtotal, hideZeroDecimals: true)}');
    if (bill.billDiscount > 0) {
      buffer.writeln('Discount: -${CurrencyFormatter.formatPaise(bill.billDiscount, hideZeroDecimals: true)}');
    }
    buffer.writeln('GRAND TOTAL: ${CurrencyFormatter.formatPaise(bill.grandTotal, hideZeroDecimals: true)}');
    buffer.writeln('Payment: ${bill.paymentType}');
    if (bill.balanceDue > 0) {
      buffer.writeln('Paid: ${CurrencyFormatter.formatPaise(bill.amountReceived, hideZeroDecimals: true)}');
      buffer.writeln('Balance Due (Udhaar): ${CurrencyFormatter.formatPaise(bill.balanceDue, hideZeroDecimals: true)}');
    }
    buffer.writeln('================================');
    buffer.writeln('Thank you for shopping with us!');
    buffer.writeln('================================');

    return buffer.toString();
  }

  static Future<void> shareReceipt(BillModel bill, {String shopName = 'ShopMint Store'}) async {
    final text = generateReceiptText(bill, shopName: shopName);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Receipt ${bill.billNo} from $shopName',
        ),
      );
    } catch (_) {
      // Fallback to clipboard if share sheet fails
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  static Future<void> copyReceipt(BillModel bill, {String shopName = 'ShopMint Store'}) async {
    final text = generateReceiptText(bill, shopName: shopName);
    await Clipboard.setData(ClipboardData(text: text));
  }

  static String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

