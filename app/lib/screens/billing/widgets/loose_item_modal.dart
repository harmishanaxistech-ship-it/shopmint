import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_model.dart';
import '../../../providers/billing_provider.dart';
import '../../../widgets/app_3d_button.dart';

class LooseItemModal extends StatefulWidget {
  final ProductModel? preselectedProduct;
  final void Function(ProductModel, [int])? onAdd;

  const LooseItemModal({
    super.key,
    this.preselectedProduct,
    this.onAdd,
  });

  static Future<void> show(
    BuildContext context, {
    ProductModel? preselectedProduct,
    void Function(ProductModel, [int])? onAdd,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => LooseItemModal(
        preselectedProduct: preselectedProduct,
        onAdd: onAdd,
      ),
    );
  }

  @override
  State<LooseItemModal> createState() => _LooseItemModalState();
}

class _LooseItemModalState extends State<LooseItemModal> {
  String unit = 'kg';
  double amount = 1.0;
  final TextEditingController rate = TextEditingController(text: '80');

  @override
  void initState() {
    super.initState();
    if (widget.preselectedProduct != null) {
      unit = widget.preselectedProduct!.unit;
      rate.text = (widget.preselectedProduct!.sellingPrice / 100).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double ratePerUnit = double.tryParse(rate.text) ?? 0.0;
    final double total = ratePerUnit * amount;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Loose item',
        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose unit', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              children: ['kg', 'g', 'litre', 'ml', 'packet', 'box']
                  .map(
                    (v) => ChoiceChip(
                      label: Text(v),
                      selected: unit == v,
                      onSelected: (_) => setState(() => unit = v),
                      selectedColor: AppColors.paleMint,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            const Text('Quick quantity', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [0.1, 0.25, 0.5, 1.0, 2.0, 5.0]
                  .map(
                    (v) => ActionChip(
                      label: Text(
                        v < 1 ? '${(v * 1000).round()}g' : '${v.toStringAsFixed(0)}$unit',
                      ),
                      onPressed: () => setState(() => amount = v),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Rate per $unit (₹)'),
                ),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: rate,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Quantity: ${amount.toStringAsFixed(amount < 1 ? 2 : 0)} $unit',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              'Total  ₹${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: App3dButton(
            label: 'ADD TO BILL  (₹${total.toStringAsFixed(0)})',
            onPressed: () {
              final looseProduct = ProductModel(
                id: 'loose_${DateTime.now().millisecondsSinceEpoch}',
                name: widget.preselectedProduct?.name ?? 'Loose $unit item',
                unit: unit,
                sellingPrice: CurrencyFormatter.toPaise(ratePerUnit),
                purchasePrice: CurrencyFormatter.toPaise(ratePerUnit * 0.8),
                currentStock: 999,
                isLoose: true,
                barcode: 'loose-${DateTime.now().millisecondsSinceEpoch}',
                color: const Color(0xFFE8F6F5),
                icon: Icons.scale_outlined,
              );

              // 1. If caller supplied onAdd callback
              widget.onAdd?.call(looseProduct, amount.round() > 0 ? amount.round() : 1);

              // 2. Also add to global BillingProvider
              try {
                final billProv = Provider.of<BillingProvider>(context, listen: false);
                billProv.addCustomItem(
                  name: looseProduct.name,
                  rate: CurrencyFormatter.toPaise(ratePerUnit),
                  qty: amount,
                  unit: unit,
                );
              } catch (_) {}

              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
