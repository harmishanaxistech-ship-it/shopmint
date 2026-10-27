import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/app_3d_button.dart';
import '../../../widgets/product_image_view.dart';

class QuickAddStockModal extends StatefulWidget {
  final ProductModel product;

  const QuickAddStockModal({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductModel product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddStockModal(product: product),
    );
  }

  @override
  State<QuickAddStockModal> createState() => _QuickAddStockModalState();
}

class _QuickAddStockModalState extends State<QuickAddStockModal> {
  final TextEditingController _amountPaidCtrl = TextEditingController();
  final TextEditingController _piecesBoughtCtrl = TextEditingController(text: '10');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.purchasePrice > 0) {
      final initialPaid = (widget.product.purchasePrice * 10 / 100);
      _amountPaidCtrl.text = initialPaid.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountPaidCtrl.dispose();
    _piecesBoughtCtrl.dispose();
    super.dispose();
  }

  double get _pieces => double.tryParse(_piecesBoughtCtrl.text.trim()) ?? 0;
  double get _totalPaid => double.tryParse(_amountPaidCtrl.text.trim()) ?? 0;

  int get _calculatedUnitCostPaise {
    if (_pieces <= 0 || _totalPaid <= 0) return widget.product.purchasePrice;
    return CurrencyFormatter.toPaise(_totalPaid / _pieces);
  }

  Future<void> _handleSave() async {
    final qty = _pieces;
    if (qty <= 0) return;

    setState(() => _isSaving = true);
    final prodProv = Provider.of<ProductProvider>(context, listen: false);

    bool success = false;
    if (widget.product.id.startsWith('sample_') || widget.product.id.startsWith('def_')) {
      final unitCost = _totalPaid > 0 ? _calculatedUnitCostPaise : widget.product.purchasePrice;
      success = await prodProv.createProduct(
        name: widget.product.name,
        barcode: widget.product.barcode,
        unit: widget.product.unit,
        purchasePrice: unitCost,
        sellingPrice: widget.product.sellingPrice,
        currentStock: widget.product.currentStock + qty,
        minStock: widget.product.minStock,
        imageUrl: widget.product.imageUrl,
      );
    } else {
      success = await prodProv.addStock(
        widget.product.id,
        qty,
        newPurchasePrice: _totalPaid > 0 ? _calculatedUnitCostPaise : null,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)} ${widget.product.unit} to ${widget.product.name}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update stock. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
            const SizedBox(height: 14),

            // Product Header Row (Exact match to screenshot)
            Row(
              children: [
                ProductImageView(
                  imageUrl: p.imageUrl,
                  width: 48,
                  height: 48,
                  borderRadius: AppRadius.smAll,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.barcode.isNotEmpty)
                        Text(
                          p.barcode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary.withAlpha(200),
                          ),
                        ),
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Current stock: ${p.currentStock.toStringAsFixed(0)} ${p.unit} • Sell: ${CurrencyFormatter.formatPaise(p.sellingPrice)}',
                        style: AppText.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 1: Total Amount Paid (₹)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount Paid (₹)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _amountPaidCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Row 2: Total Pieces Bought
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total ${p.unit == "kg" ? "Kg" : p.unit == "litre" ? "Litres" : "Pieces"} Bought',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _piecesBoughtCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tactile 3D "ADD +" Button (Exact match to reference image)
            App3dButton.mint(
              height: 48,
              onPressed: _isSaving ? null : _handleSave,
              isLoading: _isSaving,
              label: 'ADD',
              trailingIcon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}
