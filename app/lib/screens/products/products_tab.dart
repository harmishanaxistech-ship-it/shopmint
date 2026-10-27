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
import 'add_stock_modal.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'lowStock', 'loose'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleScanBarcode(LocaleProvider loc, ProductProvider prodProv) async {
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
      _searchController.text = scannedCode;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${existing.name} found (Barcode: $scannedCode)')),
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
        AddProductDialog.show(
          context,
          initialBarcode: scannedCode,
          initialName: master.name,
          initialUnit: master.unit,
          initialImageUrl: master.image,
        );
      } else {
        AddProductDialog.show(
          context,
          initialBarcode: scannedCode,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = Provider.of<ProductProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);

    final searchQuery = _searchController.text.trim().toLowerCase();
    List<ProductModel> filtered = prodProv.products.where((p) {
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery) ||
          p.barcode.toLowerCase().contains(searchQuery);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'lowStock') {
        return p.isLowStock;
      } else if (_selectedFilter == 'loose') {
        return p.isLoose;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => prodProv.fetchProducts(),
        child: Column(
          children: [
            // Search & Barcode Scan Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: loc.t('searchProductHint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryDark),
                        tooltip: loc.t('scanBarcode'),
                        onPressed: () => _handleScanBarcode(loc, prodProv),
                      ),
                    ],
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      label: Text(loc.t('addNewProduct')),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.primary),
                      onPressed: () => AddProductDialog.show(context),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.scale_outlined, size: 16, color: AppColors.primaryDark),
                      label: const Text('+ Loose Item'),
                      backgroundColor: AppColors.primarySurface,
                      side: const BorderSide(color: AppColors.primaryDark),
                      onPressed: () => AddProductDialog.show(context),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('All (${prodProv.products.length})'),
                      selected: _selectedFilter == 'all',
                      onSelected: (_) => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Low Stock (${prodProv.lowStockProducts.length})'),
                      selected: _selectedFilter == 'lowStock',
                      onSelected: (_) => setState(() => _selectedFilter = 'lowStock'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Loose Items (${prodProv.looseProducts.length})'),
                      selected: _selectedFilter == 'loose',
                      onSelected: (_) => setState(() => _selectedFilter = 'loose'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Product List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textDisabled),
                          const SizedBox(height: 12),
                          Text('No products found', style: AppText.body),
                          const SizedBox(height: 6),
                          Text(
                            'Scan any grocery barcode with your camera to add products.',
                            style: AppText.caption,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text(loc.t('scanBarcode')),
                            onPressed: () => _handleScanBarcode(loc, prodProv),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final product = filtered[idx];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Photo Thumbnail
                                ProductImageView(
                                  imageUrl: product.imageUrl,
                                  width: 48,
                                  height: 48,
                                ),
                                const SizedBox(width: 12),

                                // Product Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.name, style: AppText.label),
                                      const SizedBox(height: 3),
                                      if (product.barcode.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: AppRadius.smAll,
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.qr_code, size: 13, color: AppColors.primaryDark),
                                              const SizedBox(width: 4),
                                              Text(
                                                product.barcode,
                                                style: AppText.caption.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ] else if (product.isLoose || product.barcode.isEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySurface,
                                            borderRadius: AppRadius.smAll,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.scale_outlined, size: 13, color: AppColors.primaryDark),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Loose Item (${product.unit})',
                                                style: AppText.caption.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primaryDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Row(
                                        children: [
                                          Text(
                                            'Sell: ${CurrencyFormatter.formatPaise(product.sellingPrice)}',
                                            style: AppText.amount,
                                          ),
                                          if (product.purchasePrice > 0) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              'Cost: ${CurrencyFormatter.formatPaise(product.purchasePrice)}',
                                              style: AppText.caption,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Stock Level & Add Stock Quick Button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: product.isLowStock ? AppColors.errorSoft : AppColors.successSoft,
                                        borderRadius: AppRadius.smAll,
                                      ),
                                      child: Text(
                                        'Stock: ${product.currentStock.toStringAsFixed(0)} ${product.unit}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: product.isLowStock ? AppColors.error : AppColors.success,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    IconButton(
                                      icon: const Icon(Icons.add_box_outlined, size: 22, color: AppColors.primaryDark),
                                      tooltip: loc.t('addStock'),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) => const AddStockModal(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'products_fab',
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(loc.t('scanBarcode')),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        onPressed: () => _handleScanBarcode(loc, prodProv),
      ),
    );
  }
}

