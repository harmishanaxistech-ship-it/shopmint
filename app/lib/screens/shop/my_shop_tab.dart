import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/storage/master_catalog_service.dart';
import '../../models/product_model.dart';
import '../../models/shop_mint_models.dart';
import '../../providers/product_provider.dart';
import '../settings/settings_screen.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/shop_mint_components.dart';

class MyShopTab extends StatefulWidget {
  const MyShopTab({
    super.key,
    required this.products,
    required this.onStockUpdated,
    required this.onScanRequested,
    this.onProductUpdated,
    this.onProductDeleted,
    this.onProductAdded,
    this.onRefresh,
    this.storeName = 'Ramesh Kirana',
  });

  final List<ProductItem> products;
  final VoidCallback onStockUpdated;
  final VoidCallback onScanRequested;
  final void Function(ProductItem item)? onProductUpdated;
  final void Function(ProductItem item)? onProductDeleted;
  final void Function(ProductItem item)? onProductAdded;
  final Future<void> Function()? onRefresh;
  final String storeName;

  @override
  State<MyShopTab> createState() => _MyShopTabState();
}

class _MyShopTabState extends State<MyShopTab> {
  int _subTab = 0;
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteProduct(BuildContext context, ProductItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline_rounded, color: red, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Delete Product', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}" from your shop catalog?',
          style: const TextStyle(fontSize: 14, color: muted, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onProductDeleted?.call(item);
      widget.onStockUpdated();
      if (context.mounted) {
        showNote(context, '"${item.name}" deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = widget.products.where((p) => p.isLow).length;
    var filtered = widget.products
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()) || p.barcode.contains(_query))
        .toList();

    if (_subTab == 1) {
      filtered = filtered.where((p) => p.isLow).toList();
    }

    return Column(
      children: [
        _ShopTopBar(storeName: widget.storeName),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: segmentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentTab(
                    label: 'Shop items: ${widget.products.length}',
                    selected: _subTab == 0,
                    onTap: () => setState(() => _subTab = 0),
                  ),
                ),
                Expanded(
                  child: SegmentTab(
                    label: 'Pending',
                    badge: '$lowStockCount',
                    selected: _subTab == 1,
                    onTap: () => setState(() => _subTab = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line),
              boxShadow: const [
                BoxShadow(color: Color(0x060F766E), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: canvas,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: line),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.search_rounded, size: 20, color: muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (val) => setState(() => _query = val),
                          decoration: const InputDecoration(
                            hintText: 'Search barcode or product name',
                            hintStyle: TextStyle(fontSize: 13, color: muted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Scan barcode',
                        onPressed: widget.onScanRequested,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: teal),
                      ),
                      IconButton(
                        tooltip: 'Add loose item',
                        onPressed: () => showAddLooseProductModal(
                          context,
                          widget.products,
                          widget.onStockUpdated,
                          onAddedProduct: widget.onProductAdded,
                        ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 19, color: teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Vanik3DButton(
                        variant: VanikButtonVariant.green,
                        height: 44,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                        label: 'Add Product',
                        onPressed: () => showAddNewShopProductModal(
                          context: context,
                          products: widget.products,
                          onAdded: (newItem) {
                            widget.onProductAdded?.call(newItem);
                            widget.onStockUpdated();
                            showNote(context, '"${newItem.name}" added to shop');
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Vanik3DButton(
                        variant: VanikButtonVariant.beige,
                        height: 44,
                        icon: const Icon(Icons.inventory_2_outlined, size: 18, color: ink),
                        label: 'Stock barcode items',
                        onPressed: () {
                          if (widget.products.isNotEmpty) {
                            showVanikAddStockSheet(context, widget.products.first, widget.onStockUpdated);
                          } else {
                            showNote(context, 'Please add a product first');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: teal,
            backgroundColor: Colors.white,
            onRefresh: widget.onRefresh ?? () async {},
            child: filtered.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Text(
                            _subTab == 1
                                ? 'No pending low-stock items'
                                : widget.products.isEmpty
                                    ? 'No products in shop yet'
                                    : 'No products found',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: line),
                        boxShadow: const [
                          BoxShadow(color: Color(0x060F766E), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        children: [
                          ProductThumbnail(name: item.name, size: 50, imageUrl: item.imageUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    if (item.barcode.isNotEmpty && !item.barcode.startsWith('LOOSE-'))
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: EdgeInsets.only(right: 2),
                                                child: Icon(Icons.qr_code_2_rounded, size: 12, color: muted),
                                              ),
                                            ),
                                            TextSpan(
                                              text: item.barcode,
                                              style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else
                                      const Text.rich(
                                        TextSpan(
                                          children: [
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: EdgeInsets.only(right: 2),
                                                child: Icon(Icons.scale_outlined, size: 12, color: teal),
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'Loose',
                                              style: TextStyle(fontSize: 11, color: teal, fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: item.isLow ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '${item.stock} ${item.pack}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: item.isLow ? red : const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => showVanikAddStockSheet(context, item, widget.onStockUpdated),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: mintTint,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFCCE3DF)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add, size: 12, color: teal),
                                          Text(
                                            'Stock',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: teal),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => showEditProductModal(
                                      context: context,
                                      item: item,
                                      onUpdated: (updatedItem) {
                                        widget.onProductUpdated?.call(updatedItem);
                                        widget.onStockUpdated();
                                        showNote(context, '"${updatedItem.name}" updated');
                                      },
                                      onDeleted: () => _confirmDeleteProduct(context, item),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: canvas,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: line),
                                      ),
                                      child: const Icon(Icons.edit_outlined, size: 15, color: ink),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _confirmDeleteProduct(context, item),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, size: 15, color: red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }
}

class _ShopTopBar extends StatelessWidget {
  const _ShopTopBar({required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: mintTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CustomPaint(painter: ShopkeeperAvatarPainter()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(18, 18),
                      painter: ShopMintBrandLogoPainter(),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ShopMint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Settings',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.settings_outlined, color: muted, size: 21),
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
        ),
      );
}

void showVanikAddStockSheet(BuildContext context, ProductItem item, VoidCallback onSaved) {
  final paidController = TextEditingController(text: (item.price * 5).toInt().toString());
  final piecesController = TextEditingController(text: '10');

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final paid = double.tryParse(paidController.text) ?? 0;
        final pieces = int.tryParse(piecesController.text) ?? 1;
        final costPerPiece = pieces > 0 ? (paid / pieces) : 0.0;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ProductThumbnail(name: item.name, size: 48, imageUrl: item.imageUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.barcode,
                              style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: muted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount Paid (₹)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
                        ),
                        Container(
                          width: 90,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: line),
                          ),
                          child: TextField(
                            controller: paidController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (_) => setModalState(() {}),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pieces Bought',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
                        ),
                        Container(
                          width: 90,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: line),
                          ),
                          child: TextField(
                            controller: piecesController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (_) => setModalState(() {}),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Calculated Cost per piece: ₹${costPerPiece.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teal),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Vanik3DButton(
                    variant: VanikButtonVariant.green,
                    height: 48,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                    label: 'Add stock',
                    onPressed: () {
                      final added = int.tryParse(piecesController.text) ?? 0;
                      final paid = double.tryParse(paidController.text) ?? 0;
                      if (added > 0) {
                        item.stock += added;
                        onSaved();
                        Navigator.pop(ctx);
                        showNote(context, 'Added $added pieces to ${item.name}');
                        try {
                          final prodProv = Provider.of<ProductProvider>(context, listen: false);
                          final match = prodProv.products.firstWhere(
                            (p) => p.barcode == item.barcode || p.name == item.name,
                            orElse: () => ProductModel(id: '', name: '', purchasePrice: 0, sellingPrice: 0),
                          );
                          if (match.id.isNotEmpty) {
                            prodProv.addStock(
                              match.id,
                              added.toDouble(),
                              newPurchasePrice: paid > 0 ? ((paid / added) * 100).toInt() : null,
                            );
                          }
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildShopImagePreviewWidget(String path, {double size = 58}) {
  final clean = path.trim();
  if (clean.isEmpty) {
    return Container(
      color: mintTint,
      child: const Icon(Icons.add_a_photo_outlined, color: teal, size: 24),
    );
  }
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return Image.network(
      clean,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: mintTint,
        child: const Icon(Icons.broken_image_rounded, color: teal, size: 24),
      ),
    );
  } else {
    try {
      final f = File(clean);
      if (f.existsSync()) {
        return Image.file(
          f,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: mintTint,
            child: const Icon(Icons.broken_image_rounded, color: teal, size: 24),
          ),
        );
      }
    } catch (_) {}
    return Container(
      color: mintTint,
      child: const Icon(Icons.image_outlined, color: teal, size: 24),
    );
  }
}

Future<void> _pickImageForShopModal({
  required ImageSource source,
  required TextEditingController controller,
  required void Function(void Function()) setModalState,
}) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setModalState(() {
        controller.text = picked.path;
      });
    }
  } catch (e) {
    debugPrint('Shop image pick error: $e');
  }
}

void _showShopImagePickerSheet(
  BuildContext context, {
  required TextEditingController controller,
  required void Function(void Function()) setModalState,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Product Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: mintTint, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_rounded, color: teal),
              ),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageForShopModal(source: ImageSource.camera, controller: controller, setModalState: setModalState);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: canvas, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_outlined, color: ink),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageForShopModal(source: ImageSource.gallery, controller: controller, setModalState: setModalState);
              },
            ),
            if (controller.text.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                ),
                title: const Text('Remove Image', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(ctx);
                  setModalState(() => controller.clear());
                },
              ),
          ],
        ),
      ),
    ),
  );
}

void showEditProductModal({
  required BuildContext context,
  required ProductItem item,
  required void Function(ProductItem updated) onUpdated,
  required VoidCallback onDeleted,
}) {
  final nameCtrl = TextEditingController(text: item.name);
  final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));
  final stockCtrl = TextEditingController(text: item.stock.toString());
  final barcodeCtrl = TextEditingController(text: item.barcode);
  final imageCtrl = TextEditingController(text: item.imageUrl);
  String pack = ['piece', 'kg', 'packet', 'litre', 'g', 'bottle'].contains(item.pack.toLowerCase())
      ? item.pack.toLowerCase()
      : 'piece';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _showShopImagePickerSheet(ctx, controller: imageCtrl, setModalState: setModalState),
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: line, width: 1.5),
                                ),
                                child: _buildShopImagePreviewWidget(imageCtrl.text, size: 58),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: teal, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Product',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                InkWell(
                                  onTap: () => _pickImageForShopModal(
                                    source: ImageSource.camera,
                                    controller: imageCtrl,
                                    setModalState: setModalState,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: mintTint,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: mint),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.camera_alt_rounded, size: 13, color: teal),
                                        SizedBox(width: 4),
                                        Text('Take Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _pickImageForShopModal(
                                    source: ImageSource.gallery,
                                    controller: imageCtrl,
                                    setModalState: setModalState,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: canvas,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: line),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.photo_library_outlined, size: 13, color: muted),
                                        SizedBox(width: 4),
                                        Text('Gallery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: muted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Product Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selling Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: canvas,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: line),
                              ),
                              child: TextField(
                                controller: priceCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: canvas,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: line),
                              ),
                              child: TextField(
                                controller: stockCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Barcode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: TextField(
                      controller: barcodeCtrl,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Unit / Pack', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['piece', 'kg', 'packet', 'litre', 'g', 'bottle'].map((p) {
                        final selected = pack == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(p),
                            selected: selected,
                            selectedColor: mintTint,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? teal : muted,
                            ),
                            onSelected: (_) => setModalState(() => pack = p),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Product Image URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, size: 18, color: muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: imageCtrl,
                            onChanged: (_) => setModalState(() {}),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
                            decoration: const InputDecoration(
                              hintText: 'Paste image link (optional)',
                              hintStyle: TextStyle(fontSize: 12, color: muted),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (imageCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              imageCtrl.clear();
                              setModalState(() {});
                            },
                            child: const Icon(Icons.clear_rounded, size: 18, color: muted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _presetImageChip(
                          label: 'Biscuits',
                          url: 'https://images.openfoodfacts.org/images/products/890/171/910/1018/front_en.3.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Snacks',
                          url: 'https://images.openfoodfacts.org/images/products/890/908/100/7156/front_en.1.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Noodles',
                          url: 'https://images.openfoodfacts.org/images/products/890/105/801/0218/front_en.4.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Drink',
                          url: 'https://images.openfoodfacts.org/images/products/890/103/086/5070/front_en.3.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Grains',
                          url: 'https://images.openfoodfacts.org/images/products/890/404/390/1107/front_en.3.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Vanik3DButton(
                    variant: VanikButtonVariant.green,
                    height: 48,
                    label: 'Save Changes',
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text) ?? item.price;
                      final stock = int.tryParse(stockCtrl.text) ?? item.stock;
                      if (name.isEmpty) return;

                      item.name = name;
                      item.price = price;
                      item.stock = stock;
                      item.pack = pack;
                      item.barcode = barcodeCtrl.text.trim();
                      item.imageUrl = imageCtrl.text.trim();

                      if (item.barcode.isNotEmpty) {
                        MasterCatalogService.saveToMaster(MasterProductItem(
                          barcode: item.barcode,
                          name: item.name,
                          image: item.imageUrl,
                          unit: item.pack,
                        ));
                      }

                      Navigator.pop(ctx);
                      onUpdated(item);
                    },
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: red),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDeleted();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void showAddNewShopProductModal({
  required BuildContext context,
  required List<ProductItem> products,
  required void Function(ProductItem newItem) onAdded,
}) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '10');
  final barcodeCtrl = TextEditingController();
  final imageCtrl = TextEditingController();
  String pack = 'piece';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _showShopImagePickerSheet(ctx, controller: imageCtrl, setModalState: setModalState),
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: line, width: 1.5),
                                ),
                                child: _buildShopImagePreviewWidget(imageCtrl.text, size: 58),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: teal, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Product',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                InkWell(
                                  onTap: () => _pickImageForShopModal(
                                    source: ImageSource.camera,
                                    controller: imageCtrl,
                                    setModalState: setModalState,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: mintTint,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: mint),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.camera_alt_rounded, size: 13, color: teal),
                                        SizedBox(width: 4),
                                        Text('Take Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _pickImageForShopModal(
                                    source: ImageSource.gallery,
                                    controller: imageCtrl,
                                    setModalState: setModalState,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: canvas,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: line),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.photo_library_outlined, size: 13, color: muted),
                                        SizedBox(width: 4),
                                        Text('Gallery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: muted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                      decoration: const InputDecoration(
                        hintText: 'Product Name (e.g. Tata Salt)',
                        hintStyle: TextStyle(fontSize: 13, color: muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: line),
                          ),
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                            decoration: const InputDecoration(
                              hintText: 'Price (₹)',
                              hintStyle: TextStyle(fontSize: 13, color: muted),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: line),
                          ),
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                            decoration: const InputDecoration(
                              hintText: 'Initial Stock',
                              hintStyle: TextStyle(fontSize: 13, color: muted),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: TextField(
                      controller: barcodeCtrl,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                      decoration: const InputDecoration(
                        hintText: 'Barcode (optional, leave blank for loose)',
                        hintStyle: TextStyle(fontSize: 12, color: muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['piece', 'kg', 'packet', 'litre', 'g', 'bottle'].map((p) {
                        final selected = pack == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(p),
                            selected: selected,
                            selectedColor: mintTint,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? teal : muted,
                            ),
                            onSelected: (_) => setModalState(() => pack = p),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, size: 18, color: muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: imageCtrl,
                            onChanged: (_) => setModalState(() {}),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
                            decoration: const InputDecoration(
                              hintText: 'Product Image URL (optional)',
                              hintStyle: TextStyle(fontSize: 12, color: muted),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (imageCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              imageCtrl.clear();
                              setModalState(() {});
                            },
                            child: const Icon(Icons.clear_rounded, size: 18, color: muted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _presetImageChip(
                          label: 'Biscuits',
                          url: 'https://images.openfoodfacts.org/images/products/890/171/910/1018/front_en.3.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Snacks',
                          url: 'https://images.openfoodfacts.org/images/products/890/908/100/7156/front_en.1.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Noodles',
                          url: 'https://images.openfoodfacts.org/images/products/890/105/801/0218/front_en.4.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Drink',
                          url: 'https://images.openfoodfacts.org/images/products/890/103/086/5070/front_en.3.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Grains',
                          url: 'https://images.openfoodfacts.org/images/products/890/404/390/1107/front_en.3.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Vanik3DButton(
                    variant: VanikButtonVariant.green,
                    height: 48,
                    label: 'Save Product',
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text) ?? 10.0;
                      final stock = int.tryParse(stockCtrl.text) ?? 10;
                      if (name.isEmpty) return;

                      final barcode = barcodeCtrl.text.trim().isNotEmpty
                          ? barcodeCtrl.text.trim()
                          : 'LOOSE-${DateTime.now().millisecondsSinceEpoch}';

                      final newItem = ProductItem(
                        name: name,
                        pack: pack,
                        price: price,
                        stock: stock,
                        barcode: barcode,
                        imageUrl: imageCtrl.text.trim(),
                        profit: (price * 0.2).roundToDouble(),
                      );

                      if (newItem.barcode.isNotEmpty) {
                        MasterCatalogService.saveToMaster(MasterProductItem(
                          barcode: newItem.barcode,
                          name: newItem.name,
                          image: newItem.imageUrl,
                          unit: newItem.pack,
                        ));
                      }

                      Navigator.pop(ctx);
                      onAdded(newItem);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void showAddLooseProductModal(
  BuildContext context,
  List<ProductItem> products,
  VoidCallback onAdded, {
  void Function(ProductItem item)? onAddedProduct,
}) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '10');
  final imageCtrl = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: line, width: 1.5),
                          ),
                          child: imageCtrl.text.trim().isNotEmpty
                              ? Image.network(
                                  imageCtrl.text.trim(),
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: mintTint,
                                    child: const Icon(Icons.scale_outlined, color: teal, size: 24),
                                  ),
                                )
                              : Container(
                                  color: mintTint,
                                  child: const Icon(Icons.scale_outlined, color: teal, size: 24),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Loose Item',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                            ),
                            Text(
                              'Grains, Sugar, Vegetables, Pulses',
                              style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: muted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Item Name (e.g. Sugar / Chana Dal)',
                      hintStyle: const TextStyle(fontSize: 13, color: muted),
                      filled: true,
                      fillColor: canvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Price (₹/kg)',
                            hintStyle: const TextStyle(fontSize: 13, color: muted),
                            filled: true,
                            fillColor: canvas,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Initial Stock (kg)',
                            hintStyle: const TextStyle(fontSize: 13, color: muted),
                            filled: true,
                            fillColor: canvas,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, size: 18, color: muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: imageCtrl,
                            onChanged: (_) => setModalState(() {}),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
                            decoration: const InputDecoration(
                              hintText: 'Item Photo URL (optional)',
                              hintStyle: TextStyle(fontSize: 12, color: muted),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (imageCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              imageCtrl.clear();
                              setModalState(() {});
                            },
                            child: const Icon(Icons.clear_rounded, size: 18, color: muted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _presetImageChip(
                          label: 'Moong Dal',
                          url: 'https://images.openfoodfacts.org/images/products/890/404/390/1107/front_en.3.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                        _presetImageChip(
                          label: 'Grains',
                          url: 'https://images.openfoodfacts.org/images/products/890/105/801/0218/front_en.4.400.jpg',
                          current: imageCtrl.text,
                          onSelect: (url) {
                            imageCtrl.text = url;
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Vanik3DButton(
                    variant: VanikButtonVariant.green,
                    height: 48,
                    label: 'Save Product',
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text) ?? 40;
                      final stock = int.tryParse(stockCtrl.text) ?? 10;
                      if (name.isNotEmpty) {
                        final newItem = ProductItem(
                          name: name,
                          pack: 'kg',
                          price: price,
                          stock: stock,
                          barcode: 'LOOSE-${DateTime.now().millisecondsSinceEpoch}',
                          imageUrl: imageCtrl.text.trim(),
                          profit: price * 0.15,
                        );
                        if (onAddedProduct != null) {
                          onAddedProduct(newItem);
                        } else {
                          products.insert(0, newItem);
                        }
                        onAdded();
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _presetImageChip({
  required String label,
  required String url,
  required String current,
  required ValueChanged<String> onSelect,
}) {
  final isSelected = current == url;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      onTap: () => onSelect(isSelected ? '' : url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? mintTint : canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? teal : line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                url,
                width: 15,
                height: 15,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 13, color: muted),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? teal : ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
