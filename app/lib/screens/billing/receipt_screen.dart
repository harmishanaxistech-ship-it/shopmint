import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/receipt_share_helper.dart';
import '../../models/bill_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/shop_mint_components.dart';

class ReceiptLineItem {
  final String name;
  final double qty;
  final double price;
  ReceiptLineItem({required this.name, required this.qty, required this.price});
}

class ReceiptScreen extends StatelessWidget {
  final BillModel? bill;
  final List<dynamic>? lines;
  final double? total;
  final String? paymentMode;

  const ReceiptScreen({
    super.key,
    this.bill,
    this.lines,
    this.total,
    this.paymentMode,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String storeName = (auth.currentUser?.shopName != null &&
            auth.currentUser!.shopName.trim().isNotEmpty)
        ? auth.currentUser!.shopName
        : 'Ramesh Kirana Store';

    final String billNo = bill != null
        ? bill!.billNo
        : '#SM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final String dateString = bill != null
        ? bill!.createdAt.toString().substring(0, 16)
        : DateTime.now().toString().substring(0, 16);

    final double grandTotalRupees = total ??
        (bill != null ? (bill!.grandTotal / 100.0) : 0.0);

    final String payMode = paymentMode ?? (bill?.paymentType ?? 'Cash');

    final List<ReceiptLineItem> lineItems = [];
    if (lines != null) {
      for (final l in lines!) {
        // can be CartLine or CartItemModel
        try {
          lineItems.add(ReceiptLineItem(
            name: l.product?.name ?? l.name ?? 'Item',
            qty: (l.qty as num).toDouble(),
            price: (l.product?.price ?? (l.rate != null ? l.rate / 100.0 : 0.0)).toDouble(),
          ));
        } catch (_) {}
      }
    } else if (bill != null) {
      for (final i in bill!.items) {
        lineItems.add(ReceiptLineItem(
          name: i.name,
          qty: i.qty,
          price: i.rate / 100.0,
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Bill completed', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 16,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandWordmark()),
                        const SizedBox(height: 4),
                        Text(
                          storeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'BILL  $billNo',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateString,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Expanded(
                              child: Text('ITEM', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                            ),
                            Text('QTY', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                            SizedBox(width: 44),
                            Text('AMOUNT', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...lineItems.map(
                          (line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(line.name, style: const TextStyle(fontSize: 12)),
                                ),
                                Text('${line.qty.toInt()}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 26),
                                SizedBox(
                                  width: 54,
                                  child: Text(
                                    '₹${(line.qty * line.price).toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Subtotal', style: TextStyle(color: AppColors.muted)),
                            ),
                            Text('₹${grandTotalRupees.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Grand total',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '₹${grandTotalRupees.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Paid via $payMode',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Thank you for shopping with us!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                children: [
                  App3dButton(
                    label: 'SHARE RECEIPT',
                    icon: Icons.share_outlined,
                    onPressed: () {
                      if (bill != null) {
                        ReceiptShareHelper.shareReceipt(bill!);
                      } else {
                        Clipboard.setData(
                          ClipboardData(
                            text: '$storeName\nBill: $billNo\nTotal: ₹${grandTotalRupees.toStringAsFixed(0)}\nPaid via $payMode',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Receipt ready to share')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: '$storeName\nTotal: ₹${grandTotalRupees.toStringAsFixed(0)}\nPaid via $payMode',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Receipt copied')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Next Bill'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
