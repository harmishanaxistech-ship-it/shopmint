import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/receipt_share_helper.dart';
import '../../models/bill_model.dart';
import '../../widgets/app_3d_button.dart';
import 'new_bill_screen.dart';

class ReceiptScreen extends StatelessWidget {
  final BillModel bill;

  const ReceiptScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy, hh:mm a');
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.t('receiptTitle')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Receipt',
            onPressed: () => ReceiptShareHelper.shareReceipt(bill),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.success.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Generated Successfully',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'Bill No: ${bill.billNo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share Actions Hub (WhatsApp & System Share)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.send_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Fast Bill Sharing', style: AppText.h3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: App3dButton.mint(
                          height: 48,
                          icon: Icons.share,
                          label: 'Share Receipt',
                          onPressed: () => ReceiptShareHelper.shareReceipt(bill),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        onPressed: () async {
                          await ReceiptShareHelper.copyReceipt(bill);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Receipt text copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Printable / Thermal Receipt Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(loc.t('receiptTitle'), style: AppText.h2),
                        const SizedBox(height: 4),
                        Text('${loc.t('billNo')}: ${bill.billNo}', style: AppText.label),
                        Text(dateFormat.format(bill.createdAt), style: AppText.caption),
                      ],
                    ),
                  ),
                  const Divider(height: 28),

                  // Customer info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.t('customer')}: ${bill.customerName}', style: AppText.bodyLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bill.paymentType == 'Credit' ? AppColors.errorSoft : AppColors.successSoft,
                          borderRadius: AppRadius.smAll,
                        ),
                        child: Text(
                          bill.paymentType,
                          style: AppText.label.copyWith(
                            color: bill.paymentType == 'Credit' ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Items Table Header
                  Row(
                    children: [
                      Expanded(flex: 4, child: Text(loc.t('itemName'), style: AppText.caption)),
                      Expanded(flex: 2, child: Text(loc.t('qty'), textAlign: TextAlign.center, style: AppText.caption)),
                      Expanded(flex: 2, child: Text(loc.t('rate'), textAlign: TextAlign.right, style: AppText.caption)),
                      Expanded(flex: 3, child: Text(loc.t('amount'), textAlign: TextAlign.right, style: AppText.caption)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Items Rows
                  ...bill.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Text(item.name, style: AppText.body)),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2)} ${item.unit}',
                              textAlign: TextAlign.center,
                              style: AppText.caption,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              CurrencyFormatter.formatPaise(item.rate, hideZeroDecimals: true),
                              textAlign: TextAlign.right,
                              style: AppText.caption,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              CurrencyFormatter.formatPaise(item.amount),
                              textAlign: TextAlign.right,
                              style: AppText.amount,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 24),

                  // Subtotal & Discount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: AppText.caption),
                      Text(CurrencyFormatter.formatPaise(bill.subtotal), style: AppText.caption),
                    ],
                  ),
                  if (bill.billDiscount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount', style: AppText.caption.copyWith(color: AppColors.success)),
                        Text('-${CurrencyFormatter.formatPaise(bill.billDiscount)}', style: AppText.caption.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Grand Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.t('grandTotal')}:', style: AppText.h3),
                      Text(
                        CurrencyFormatter.formatPaise(bill.grandTotal),
                        style: AppText.amountLarge,
                      ),
                    ],
                  ),

                  if (bill.balanceDue > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${loc.t('received')}:', style: AppText.caption),
                        Text(CurrencyFormatter.formatPaise(bill.amountReceived), style: AppText.caption),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${loc.t('balanceDue')}:', style: AppText.label.copyWith(color: AppColors.error)),
                        Text(
                          CurrencyFormatter.formatPaise(bill.balanceDue),
                          style: AppText.amount.copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  Center(
                    child: Text(loc.t('thankYou'), style: AppText.caption),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions: Next Bill & Home
            App3dButton.mint(
              height: 50,
              icon: Icons.add_shopping_cart,
              label: loc.t('nextBill'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const NewBillScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(loc.t('done')),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
