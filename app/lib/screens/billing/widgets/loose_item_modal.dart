import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_model.dart';
import '../../../providers/billing_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/app_3d_button.dart';

class LooseItemModal extends StatefulWidget {
  final ProductModel? preselectedProduct;

  const LooseItemModal({super.key, this.preselectedProduct});

  static Future<void> show(BuildContext context, {ProductModel? preselectedProduct}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LooseItemModal(preselectedProduct: preselectedProduct),
    );
  }

  @override
  State<LooseItemModal> createState() => _LooseItemModalState();
}

class _LooseItemModalState extends State<LooseItemModal> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1.0');

  String _selectedUnit = 'kg';
  ProductModel? _selectedProduct;

  final List<String> _units = ['kg', 'g', 'litre', 'ml', 'dozen', 'pcs'];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedProduct != null) {
      _applyProduct(widget.preselectedProduct!);
    }
  }

  void _applyProduct(ProductModel prod) {
    _selectedProduct = prod;
    _nameCtrl.text = prod.name;
    _selectedUnit = prod.unit.isNotEmpty ? prod.unit : 'kg';
    _rateCtrl.text = (prod.sellingPrice / 100).toStringAsFixed(0);
    _qtyCtrl.text = '1.0';
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  double get _currentQty => double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;
  double get _currentRate => double.tryParse(_rateCtrl.text.trim()) ?? 0.0;

  double get _calculatedTotalRupees {
    if (_selectedUnit == 'g') {
      return (_currentQty / 1000.0) * _currentRate;
    } else if (_selectedUnit == 'ml') {
      return (_currentQty / 1000.0) * _currentRate;
    }
    return _currentQty * _currentRate;
  }

  void _applyPresetWeight(double qty, String unit) {
    setState(() {
      _selectedUnit = unit;
      _qtyCtrl.text = qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = Provider.of<ProductProvider>(context);
    final billProv = Provider.of<BillingProvider>(context, listen: false);

    // Filter loose products from shop inventory
    final looseProducts = prodProv.products.where((p) => p.isLoose || p.barcode.isEmpty).toList();

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Handle & Title
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadius.smAll,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: const Icon(Icons.scale_outlined, size: 18, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 8),
                    Text('Loose / Non-Barcode Item', style: AppText.h3),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Picker of Existing Loose Items (if any in store)
            if (looseProducts.isNotEmpty) ...[
              Text('Shop Loose Staples:', style: AppText.caption),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: looseProducts.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 6),
                  itemBuilder: (ctx, idx) {
                    final p = looseProducts[idx];
                    final isChosen = _selectedProduct?.id == p.id;
                    return InkWell(
                      onTap: () => _applyProduct(p),
                      borderRadius: AppRadius.smAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isChosen ? AppColors.primaryDark : AppColors.background,
                          borderRadius: AppRadius.smAll,
                          border: Border.all(
                            color: isChosen ? AppColors.primaryDark : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '${p.name} (${CurrencyFormatter.formatPaise(p.sellingPrice)}/${p.unit})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isChosen ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Item Name Input
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Name (e.g. Sugar, Wheat, Loose Oil, Milk)',
                prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 10),

            // Rate and Unit Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Rate (Price per Unit)',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Preset Weight / Measure Chips
            Text('Quick Presets:', style: AppText.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_selectedUnit == 'kg' || _selectedUnit == 'g') ...[
                  _presetChip('100g', 0.1, 'kg'),
                  _presetChip('250g', 0.25, 'kg'),
                  _presetChip('500g (1/2 kg)', 0.5, 'kg'),
                  _presetChip('1 kg', 1.0, 'kg'),
                  _presetChip('2 kg', 2.0, 'kg'),
                  _presetChip('5 kg', 5.0, 'kg'),
                ] else if (_selectedUnit == 'litre' || _selectedUnit == 'ml') ...[
                  _presetChip('200ml', 0.2, 'litre'),
                  _presetChip('500ml (Half L)', 0.5, 'litre'),
                  _presetChip('1 Litre', 1.0, 'litre'),
                  _presetChip('2 Litre', 2.0, 'litre'),
                  _presetChip('5 Litre', 5.0, 'litre'),
                ] else ...[
                  _presetChip('0.5 (Half)', 0.5, _selectedUnit),
                  _presetChip('1 (Single)', 1.0, _selectedUnit),
                  _presetChip('2', 2.0, _selectedUnit),
                  _presetChip('5', 5.0, _selectedUnit),
                  _presetChip('10', 10.0, _selectedUnit),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Quantity / Weight input
            TextField(
              controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Quantity / Weight to Sell',
                suffixText: _selectedUnit,
                prefixIcon: const Icon(Icons.scale, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 14),

            // Live Calculation Total Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Calculated Amount', style: AppText.caption),
                      Text(
                        '$_currentQty $_selectedUnit x ₹${_currentRate.toStringAsFixed(0)}/$_selectedUnit',
                        style: AppText.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.formatPaise(CurrencyFormatter.toPaise(_calculatedTotalRupees)),
                    style: AppText.amountLarge.copyWith(color: AppColors.primaryDark, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Add to Bill Tactile 3D Button
            App3dButton.mint(
              height: 48,
              icon: Icons.add_shopping_cart,
              label: 'Add to Bill (${CurrencyFormatter.formatPaise(CurrencyFormatter.toPaise(_calculatedTotalRupees))})',
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final rate = _currentRate;
                final qty = _currentQty;

                if (name.isEmpty || rate <= 0 || qty <= 0) return;

                if (_selectedProduct != null) {
                  billProv.addItemFromProduct(_selectedProduct!, qty: qty);
                } else {
                  billProv.addCustomItem(
                    name: name,
                    rate: CurrencyFormatter.toPaise(rate),
                    qty: qty,
                    unit: _selectedUnit,
                  );
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, double qty, String unit) {
    final isSelected = (_currentQty == qty) && (_selectedUnit == unit);
    return InkWell(
      onTap: () => _applyPresetWeight(qty, unit),
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.background,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
