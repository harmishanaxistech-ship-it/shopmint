import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/storage/master_catalog_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_image_view.dart';
import '../billing/barcode_scanner_modal.dart';
import 'add_product_dialog.dart';

class AddStockModal extends StatefulWidget {
  const AddStockModal({super.key});

  @override
  State<AddStockModal> createState() => _AddStockModalState();
}

class _AddStockModalState extends State<AddStockModal> {
  ProductModel? _selectedProduct;
  final _qtyController = TextEditingController(text: '1');
  final _costController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) return;
    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) return;

    final cost = double.tryParse(_costController.text);
    final costPaise = cost != null ? CurrencyFormatter.toPaise(cost) : null;

    setState(() => _isSaving = true);
    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final success = await prodProv.addStock(_selectedProduct!.id, qty, newPurchasePrice: costPaise);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated successfully')),
      );
    }
  }

  Future<void> _handleBarcodeScan(LocaleProvider loc, ProductProvider prodProv) async {
    final scannedCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BarcodeScannerModal(),
    );

    if (scannedCode == null || scannedCode.isEmpty || !mounted) return;

    final existing = prodProv.products.cast<ProductModel?>().firstWhere(
      (p) => p?.barcode == scannedCode,
      orElse: () => null,
    );

    if (existing != null) {
      setState(() {
        _selectedProduct = existing;
        if (existing.purchasePrice > 0) {
          _costController.text = (existing.purchasePrice / 100.0).toStringAsFixed(0);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${existing.name} selected')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Looking up barcode $scannedCode...')),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      final master = await MasterCatalogService.lookupBarcode(scannedCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (master != null) {
        final newProd = await AddProductDialog.show(
          context,
          initialBarcode: scannedCode,
          initialName: master.name,
          initialUnit: master.unit,
          initialImageUrl: master.image,
        );
        if (newProd != null && mounted) {
          setState(() {
            _selectedProduct = newProd;
            if (newProd.purchasePrice > 0) {
              _costController.text = (newProd.purchasePrice / 100.0).toStringAsFixed(0);
            }
          });
        }
      } else {
        final newProd = await AddProductDialog.show(
          context,
          initialBarcode: scannedCode,
        );
        if (newProd != null && mounted) {
          setState(() {
            _selectedProduct = newProd;
            if (newProd.purchasePrice > 0) {
              _costController.text = (newProd.purchasePrice / 100.0).toStringAsFixed(0);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = Provider.of<ProductProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);
    final products = prodProv.products;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.t('addStock'), style: AppText.h3),
              IconButton.filledTonal(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                tooltip: loc.t('scanBarcode'),
                onPressed: () => _handleBarcodeScan(loc, prodProv),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Image preview if selected
          if (_selectedProduct != null && _selectedProduct!.imageUrl.isNotEmpty) ...[
            Center(
              child: ProductImageView(
                imageUrl: _selectedProduct!.imageUrl,
                width: 72,
                height: 72,
                borderRadius: AppRadius.mdAll,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Product selector dropdown
          DropdownButtonFormField<ProductModel>(
            isExpanded: true,
            decoration: InputDecoration(labelText: '${loc.t('itemName')} *'),
            initialValue: _selectedProduct,
            items: products.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(
                  '${p.name} (Stock: ${p.currentStock.toStringAsFixed(0)})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedProduct = val;
                if (val != null && val.purchasePrice > 0) {
                  _costController.text = (val.purchasePrice / 100.0).toStringAsFixed(0);
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // Quantity
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${loc.t('qty')} *',
              hintText: 'e.g. 10',
            ),
          ),
          const SizedBox(height: 12),

          // Cost price
          TextField(
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${loc.t('costPrice')} (₹)',
              hintText: 'e.g. 80',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 20),

          // Button
          FilledButton(
            onPressed: (_selectedProduct == null || _isSaving) ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : Text(loc.t('save')),
          ),
        ],
      ),
    );
  }
}
