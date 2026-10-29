import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/shop_mint_components.dart';
import '../billing/barcode_scanner_modal.dart';
import '../billing/widgets/loose_item_modal.dart';
import '../products/widgets/quick_add_stock_modal.dart';
import '../settings/settings_screen.dart';

class DashboardTab extends StatefulWidget {
  final List<ProductModel>? products;
  final void Function(ProductModel, [int])? onAdd;
  final VoidCallback? onChanged;

  const DashboardTab({
    super.key,
    this.products,
    this.onAdd,
    this.onChanged,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final searchController = TextEditingController();
  bool lowOnly = false;
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _handleScanBarcode(List<ProductModel> products) async {
    final scannedResult = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BarcodeScannerModal(),
    );

    if (scannedResult == null || !mounted) return;

    String? code;
    if (scannedResult is List<String> && scannedResult.isNotEmpty) {
      code = scannedResult.first;
    } else if (scannedResult is String && scannedResult.isNotEmpty) {
      code = scannedResult;
    }

    if (code == null) return;

    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final lookup = await prodProv.lookupBarcode(code);

    if (!mounted) return;

    if (lookup.foundInShop && lookup.existingProduct != null) {
      QuickAddStockModal.show(context, lookup.existingProduct!, onChanged: () => setState(() {}));
    } else {
      // Find among current products or open quick add with first item
      final matched = products.firstWhere(
        (p) => p.barcode == code,
        orElse: () => products.first,
      );
      QuickAddStockModal.show(context, matched, onChanged: () => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final prodProv = Provider.of<ProductProvider>(context);
    final billProv = Provider.of<BillingProvider>(context);

    final shopName = (auth.currentUser?.shopName != null &&
            auth.currentUser!.shopName.trim().isNotEmpty)
        ? auth.currentUser!.shopName
        : 'Ramesh Kirana Store';

    final allProducts = widget.products ??
        (prodProv.products.isNotEmpty ? prodProv.products : ProductModel.demoProducts);

    final filtered = allProducts.where((p) {
      final matchesLow = !lowOnly || p.isLow;
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.barcode.contains(query);
      return matchesLow && matchesQuery;
    }).toList();

    void onAddProduct(ProductModel p, [int qty = 1]) {
      if (widget.onAdd != null) {
        widget.onAdd!(p, qty);
      } else {
        billProv.addItemFromProduct(p, qty: qty.toDouble());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${p.name} added to bill'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.green,
          ),
        );
      }
    }

    return SafeArea(
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.paleMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: AppColors.teal,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Shop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const BrandWordmark(),
                const SizedBox(width: 7),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined, color: AppColors.muted),
                ),
              ],
            ),
          ),

          // Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilterButton(
                    label: 'Shop items: ${allProducts.length}',
                    active: !lowOnly,
                    onTap: () => setState(() => lowOnly = false),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilterButton(
                    label: 'Low stock: ${allProducts.where((p) => p.isLow).length}',
                    active: lowOnly,
                    onTap: () => setState(() => lowOnly = true),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar & Small Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: searchController,
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search barcode item',
                        hintStyle: const TextStyle(
                          color: Color(0xFF91AAA7),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.muted,
                          size: 21,
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => query = '');
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SmallAction(
                  icon: Icons.qr_code_scanner,
                  onTap: () => _handleScanBarcode(allProducts),
                ),
                const SizedBox(width: 8),
                SmallAction(
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => LooseItemModal.show(context, onAdd: onAddProduct),
                ),
              ],
            ),
          ),

          // Wide 3D Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: App3dButton(
              label: '▥  STOCK BARCODE ITEMS',
              onPressed: () => _handleScanBarcode(allProducts),
            ),
          ),
          const SizedBox(height: 14),

          // Inventory Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Text(
                  'Inventory',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} products',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Product List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) =>
                        const Divider(height: 1, color: Color(0xFFDDF0ED)),
                    itemBuilder: (context, index) => ProductRow(
                      product: filtered[index],
                      onTap: () => QuickAddStockModal.show(
                        context,
                        filtered[index],
                        onChanged: () {
                          widget.onChanged?.call();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
