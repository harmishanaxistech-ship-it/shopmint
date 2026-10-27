import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/product_image_view.dart';
import '../billing/barcode_scanner_modal.dart';
import '../billing/widgets/loose_item_modal.dart';
import '../products/add_product_dialog.dart';
import '../products/widgets/quick_add_stock_modal.dart';
import '../settings/settings_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _activeFilter = 0; // 0: Shop items, 1: Pending / Low stock

  static final List<ProductModel> _sampleProducts = [
    ProductModel(
      id: 'sample_mad_angles',
      name: 'Mad Angles',
      barcode: '8901725131234',
      unit: 'pcs',
      sellingPrice: 2000,
      purchasePrice: 1600,
      currentStock: 55,
      minStock: 10,
      imageUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=200',
    ),
    ProductModel(
      id: 'sample_coconut_water',
      name: 'Coconut Water',
      barcode: '8901234567891',
      unit: 'pcs',
      sellingPrice: 6000,
      purchasePrice: 4800,
      currentStock: 15,
      minStock: 5,
      imageUrl: 'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?w=200',
    ),
    ProductModel(
      id: 'sample_peanut_butter',
      name: 'Peanut Butter',
      barcode: '8901234567892',
      unit: 'pcs',
      sellingPrice: 29900,
      purchasePrice: 24000,
      currentStock: 3,
      minStock: 5,
      imageUrl: 'https://images.unsplash.com/photo-1589733955941-5eeaf752f6dd?w=200',
    ),
    ProductModel(
      id: 'sample_dark_fantasy',
      name: 'Dark Fantasy Biscuits',
      barcode: '8901234567890',
      unit: 'pcs',
      sellingPrice: 3000,
      purchasePrice: 2400,
      currentStock: 54,
      minStock: 10,
      imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200',
    ),
    ProductModel(
      id: 'sample_instant_noodles',
      name: 'Instant Noodles',
      barcode: '8901234567893',
      unit: 'pcs',
      sellingPrice: 1400,
      purchasePrice: 1100,
      currentStock: 113,
      minStock: 20,
      imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200',
    ),
    ProductModel(
      id: 'sample_yogurt_cups',
      name: 'Yogurt Cups',
      barcode: '8901234567894',
      unit: 'pcs',
      sellingPrice: 3500,
      purchasePrice: 2800,
      currentStock: 142,
      minStock: 15,
      imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=200',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleStockBarcodeItems() async {
    final scannedResult = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BarcodeScannerModal(),
    );

    if (scannedResult == null || !mounted) return;

    final List<String> codes = [];
    if (scannedResult is List<String>) {
      codes.addAll(scannedResult);
    } else if (scannedResult is String && scannedResult.isNotEmpty) {
      codes.add(scannedResult);
    }

    if (codes.isEmpty) return;

    final code = codes.first;
    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final result = await prodProv.lookupBarcode(code);

    if (!mounted) return;

    if (result.foundInShop && result.existingProduct != null) {
      QuickAddStockModal.show(context, result.existingProduct!);
    } else if (result.foundInMaster && result.masterItem != null) {
      AddProductDialog.show(
        context,
        initialBarcode: code,
        initialName: result.masterItem!.name,
        initialUnit: result.masterItem!.unit,
        initialImageUrl: result.masterItem!.image,
      );
    } else {
      AddProductDialog.show(
        context,
        initialBarcode: code,
      );
    }
  }

  List<ProductModel> _getFilteredProducts(List<ProductModel> liveProducts) {
    List<ProductModel> base = List.from(liveProducts);
    if (base.isEmpty) {
      base = List.from(_sampleProducts);
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      base = base.where((p) {
        return p.name.toLowerCase().contains(query) || p.barcode.contains(query);
      }).toList();
    }

    if (_activeFilter == 1) {
      base = base.where((p) => p.isLowStock).toList();
    }

    return base;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final prodProv = Provider.of<ProductProvider>(context);
    final dashProv = Provider.of<DashboardProvider>(context);
    final user = auth.currentUser;

    final liveProducts = prodProv.products;
    final allItemsList = liveProducts.isNotEmpty ? liveProducts : _sampleProducts;
    final totalItemsCount = allItemsList.length;
    final lowStockCount = allItemsList.where((p) => p.isLowStock).length;

    final displayProducts = _getFilteredProducts(liveProducts);

    final shopName = (user?.shopName != null && user!.shopName.trim().isNotEmpty)
        ? user.shopName
        : 'Ramesh Kirana Store';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top ShopMint Header Bar (Matches Screenshot)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Avatar + "My Shop" + Shop Name
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withAlpha(50)),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.primaryDark,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Shop',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shopName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right: ShopMint Brand Typography + Settings
                  Row(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Shop',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            TextSpan(
                              text: 'Mint',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Pills Row (Shop items vs Pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  // Filter 1: Shop items: X
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeFilter = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFilter == 0
                              ? AppColors.primarySurface
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeFilter == 0
                                ? AppColors.primary.withAlpha(120)
                                : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Shop items: $totalItemsCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _activeFilter == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: _activeFilter == 0 ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter 2: Pending / Low stock
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeFilter = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFilter == 1
                              ? AppColors.primarySurface
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeFilter == 1
                                ? AppColors.primary.withAlpha(120)
                                : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          lowStockCount > 0 ? 'Low stock: $lowStockCount' : 'Pending 0',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _activeFilter == 1 ? FontWeight.w700 : FontWeight.w500,
                            color: _activeFilter == 1 ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Shortcut Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search barcode item',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textDisabled),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Barcode Icon Button
                  InkWell(
                    onTap: _handleStockBarcodeItems,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Loose / Bag Item Button
                  InkWell(
                    onTap: () => LooseItemModal.show(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Primary Full-Width Action Button: "Stock barcode items"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: App3dButton.mint(
                onPressed: _handleStockBarcodeItems,
                icon: Icons.qr_code_scanner,
                label: 'Stock barcode items',
                height: 48,
              ),
            ),

            // Product List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await prodProv.fetchProducts();
                  await dashProv.fetchDashboard();
                },
                child: displayProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textDisabled),
                            SizedBox(height: 8),
                            Text(
                              'No matching items found',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: displayProducts.length,
                        separatorBuilder: (_, index) => const Divider(
                          height: 1,
                          indent: 62,
                          color: AppColors.divider,
                        ),
                        itemBuilder: (ctx, idx) {
                          final p = displayProducts[idx];
                          final isLow = p.isLowStock;
                          final unitDisplay = p.unit == 'pcs' ? 'pieces' : p.unit;

                          return InkWell(
                            onTap: () => QuickAddStockModal.show(context, p),
                            borderRadius: AppRadius.smAll,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Row(
                                children: [
                                  // Product Thumbnail
                                  ProductImageView(
                                    imageUrl: p.imageUrl,
                                    width: 46,
                                    height: 46,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & Pieces
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${p.currentStock.toInt()} $unitDisplay',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isLow ? FontWeight.w700 : FontWeight.w400,
                                            color: isLow ? const Color(0xFFDC2626) : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Price & Chevron
                                  Text(
                                    CurrencyFormatter.formatPaise(p.sellingPrice),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: AppColors.textDisabled,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
