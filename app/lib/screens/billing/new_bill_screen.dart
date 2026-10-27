import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../khata/add_customer_modal.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/product_image_view.dart';
import '../products/add_product_dialog.dart';
import 'barcode_scanner_modal.dart';
import 'receipt_screen.dart';
import 'widgets/loose_item_modal.dart';

class NewBillScreen extends StatefulWidget {
  final List<String>? initialBarcodes;
  final bool isEmbedded;

  const NewBillScreen({
    super.key,
    this.initialBarcodes,
    this.isEmbedded = false,
  });

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcodes != null && widget.initialBarcodes!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        _processScannedCodes(widget.initialBarcodes!, loc);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomItemDialog(LocaleProvider loc, {String? prefilledName}) {
    final nameCtrl = TextEditingController(text: prefilledName ?? '');
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          title: Text(loc.t('customItemTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: prefilledName == null,
                decoration: InputDecoration(
                  labelText: loc.t('itemName'),
                  hintText: loc.t('itemNameHint'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                autofocus: prefilledName != null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.t('price'),
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.t('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (name.isNotEmpty && price > 0) {
                  Provider.of<BillingProvider>(context, listen: false).addCustomItem(
                    name: name,
                    rate: CurrencyFormatter.toPaise(price),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: Text(loc.t('save')),
            ),
          ],
        );
      },
    );
  }

  void _showEditQuantityDialog(BuildContext context, int index, CartItem item) {
    final qtyCtrl = TextEditingController(
      text: item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          title: Text('Edit Quantity: ${item.name}'),
          content: TextField(
            controller: qtyCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity (${item.unit})',
              suffixText: item.unit,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
              onPressed: () {
                final newQty = double.tryParse(qtyCtrl.text.trim()) ?? item.qty;
                if (newQty > 0) {
                  Provider.of<BillingProvider>(context, listen: false).updateQuantity(index, newQty);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processScannedCodes(List<String> codes, LocaleProvider loc) async {
    if (codes.isEmpty || !mounted) return;
    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final billProv = Provider.of<BillingProvider>(context, listen: false);

    int addedCount = 0;
    final List<String> unresolvedCodes = [];

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
            Expanded(
              child: Text(
                'Checking ${codes.length} scanned ${codes.length == 1 ? "item" : "items"}...',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    for (final code in codes) {
      final result = await prodProv.lookupBarcode(code);
      if (result.foundInShop && result.existingProduct != null) {
        billProv.addItemFromProduct(result.existingProduct!);
        addedCount++;
      } else {
        unresolvedCodes.add(code);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount ${addedCount == 1 ? loc.t("item") : loc.t("items")} ${loc.t("itemAdded")}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (unresolvedCodes.isNotEmpty && mounted) {
      final code = unresolvedCodes.first;
      final result = await prodProv.lookupBarcode(code);
      if (!mounted) return;

      if (result.foundInMaster && result.masterItem != null) {
        AddProductDialog.show(
          context,
          initialBarcode: code,
          initialName: result.masterItem!.name,
          initialUnit: result.masterItem!.unit,
          initialImageUrl: result.masterItem!.image,
          isFromBilling: true,
        );
      } else {
        AddProductDialog.show(
          context,
          initialBarcode: code,
          isFromBilling: true,
        );
      }
    }
  }

  void _handleBarcodeScan(LocaleProvider loc) async {
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

    if (codes.isNotEmpty) {
      await _processScannedCodes(codes, loc);
    }
  }

  Widget _buildQuickItemsBar(
    BuildContext context,
    ProductProvider prodProv,
    BillingProvider billProv,
    LocaleProvider loc,
  ) {
    // Top fast-moving items or fallback Kirana staples
    final products = prodProv.products;
    final List<Widget> chips = [];

    // First chip: Add loose item by weight
    chips.add(
      ActionChip(
        avatar: const Icon(Icons.scale_outlined, size: 16, color: AppColors.primaryDark),
        label: const Text('Loose Item'),
        backgroundColor: AppColors.primarySurface,
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        onPressed: () => LooseItemModal.show(context),
      ),
    );

    // Second chip: Add custom loose item
    chips.add(
      ActionChip(
        avatar: const Icon(Icons.add, size: 16, color: AppColors.primaryDark),
        label: Text(loc.t('customItem')),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        onPressed: () => _showAddCustomItemDialog(loc),
      ),
    );

    if (products.isNotEmpty) {
      final displayProducts = products.take(10);
      for (final p in displayProducts) {
        final isLooseProduct = p.isLoose || p.unit == 'kg' || p.unit == 'g' || p.unit == 'litre' || p.unit == 'ml';
        chips.add(
          ActionChip(
            avatar: p.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: ProductImageView(imageUrl: p.imageUrl, width: 20, height: 20),
                  )
                : Icon(
                    isLooseProduct ? Icons.scale_outlined : Icons.inventory_2_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
            label: Text(
              '${p.name} (${CurrencyFormatter.formatPaise(p.sellingPrice)})',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border, width: 1),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            onPressed: () {
              if (isLooseProduct) {
                LooseItemModal.show(context, preselectedProduct: p);
              } else {
                billProv.addItemFromProduct(p);
              }
            },
          ),
        );
      }
    } else {
      // Default standard staples for quick loose billing
      final commonStaples = ['Milk', 'Sugar', 'Bread', 'Tea', 'Rice', 'Oil', 'Atta', 'Eggs'];
      for (final staple in commonStaples) {
        chips.add(
          ActionChip(
            avatar: const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primaryDark),
            label: Text(
              staple,
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border, width: 1),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            onPressed: () => _showAddCustomItemDialog(loc, prefilledName: staple),
          ),
        );
      }
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, idx) => chips[idx],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProv = Provider.of<BillingProvider>(context);
    final custProv = Provider.of<CustomerProvider>(context);
    final prodProv = Provider.of<ProductProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);

    final totalQuantity = billProv.items.fold<double>(0, (sum, item) => sum + item.qty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: Text(widget.isEmbedded ? loc.t('makeBill') : loc.t('newBillTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: loc.t('scanBarcode'),
            onPressed: () => _handleBarcodeScan(loc),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: loc.t('customItem'),
            onPressed: () => _showAddCustomItemDialog(loc),
          ),
          if (billProv.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cart',
              onPressed: () => billProv.clearCart(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Quick Barcode Scan Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Autocomplete<ProductModel>(
              displayStringForOption: (p) => p.name,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<ProductModel>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return prodProv.products.where((p) {
                  return p.name.toLowerCase().contains(query) ||
                      p.barcode.contains(textEditingValue.text);
                });
              },
              onSelected: (prod) {
                billProv.addItemFromProduct(prod);
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: AppRadius.mdAll,
                    color: AppColors.surface,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 250,
                        maxWidth: MediaQuery.of(context).size.width - 32,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final prod = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            leading: ProductImageView(
                              imageUrl: prod.imageUrl,
                              width: 38,
                              height: 38,
                            ),
                            title: Text(
                              prod.name,
                              style: AppText.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Stock: ${prod.currentStock.toStringAsFixed(0)} ${prod.unit}${prod.barcode.isNotEmpty ? ' : ${prod.barcode}' : ''}',
                              style: AppText.caption,
                            ),
                            trailing: Text(
                              CurrencyFormatter.formatPaise(prod.sellingPrice),
                              style: AppText.amount,
                            ),
                            onTap: () => onSelected(prod),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: loc.t('searchProductHint'),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryDark),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => controller.clear(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryDark),
                          tooltip: loc.t('scanBarcode'),
                          onPressed: () => _handleBarcodeScan(loc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 1-Tap Quick Staples Bar
          _buildQuickItemsBar(context, prodProv, billProv, loc),
          const SizedBox(height: 6),

          // Cart Items List
          Expanded(
            child: billProv.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 54, color: AppColors.textDisabled),
                        const SizedBox(height: 12),
                        Text(loc.t('cartEmpty'), style: AppText.bodyLarge),
                        const SizedBox(height: 6),
                        Text(loc.t('cartEmptyHint'), style: AppText.caption),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                            side: const BorderSide(color: AppColors.primaryDark),
                          ),
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryDark),
                          label: Text(loc.t('scanBarcode'), style: const TextStyle(color: AppColors.primaryDark)),
                          onPressed: () => _handleBarcodeScan(loc),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: billProv.items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = billProv.items[idx];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            // Product Image Thumbnail
                            ProductImageView(
                              imageUrl: item.displayImageUrl,
                              width: 44,
                              height: 44,
                            ),
                            const SizedBox(width: 10),

                            // Item details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppText.label.copyWith(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  if (item.product?.barcode != null && item.product!.barcode.isNotEmpty) ...[
                                    Text(
                                      'Barcode: ${item.product!.barcode}',
                                      style: AppText.caption.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    '${loc.t('rate')}: ${CurrencyFormatter.formatPaise(item.rate)} / ${item.unit}',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ),

                            // Tactile Quantity Stepper
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Minus button
                                InkWell(
                                  onTap: () => billProv.updateQuantity(idx, item.qty - 1),
                                  borderRadius: AppRadius.smAll,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: AppRadius.smAll,
                                    ),
                                    child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Quantity badge (tap to edit)
                                InkWell(
                                  onTap: () => _showEditQuantityDialog(context, idx, item),
                                  borderRadius: AppRadius.smAll,
                                  child: Container(
                                    constraints: const BoxConstraints(minWidth: 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      borderRadius: AppRadius.smAll,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2),
                                      style: AppText.amount.copyWith(
                                        color: AppColors.primaryDark,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Plus button
                                InkWell(
                                  onTap: () => billProv.updateQuantity(idx, item.qty + 1),
                                  borderRadius: AppRadius.smAll,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: AppRadius.smAll,
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 10),

                            // Line total
                            Text(
                              CurrencyFormatter.formatPaise(item.lineTotal),
                              style: AppText.amount,
                            ),

                            const SizedBox(width: 4),

                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => billProv.removeItem(idx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Fast Checkout Panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cart Info Header (Item count & Total quantity)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${billProv.items.length} ${billProv.items.length == 1 ? loc.t("item") : loc.t("items")} : ${totalQuantity.toStringAsFixed(totalQuantity % 1 == 0 ? 0 : 1)} units',
                        style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      if (billProv.items.isNotEmpty)
                        GestureDetector(
                          onTap: () => billProv.clearCart(),
                          child: Text(
                            'Reset Cart',
                            style: AppText.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Customer Selector
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CustomerModel?>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: loc.t('customerForCredit'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          initialValue: billProv.selectedCustomer,
                          items: [
                            DropdownMenuItem<CustomerModel?>(
                              value: null,
                              child: Text(
                                loc.t('walkInCustomer'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...custProv.customers.map(
                              (c) => DropdownMenuItem<CustomerModel?>(
                                value: c,
                                child: Text(
                                  '${c.name} ${c.mobile.isNotEmpty ? "(${c.mobile})" : ""}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => billProv.setCustomer(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                        ),
                        icon: const Icon(Icons.person_add_outlined),
                        onPressed: () async {
                          final newCust = await showModalBottomSheet<CustomerModel>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const AddCustomerModal(),
                          );
                          if (newCust != null) {
                            billProv.setCustomer(newCust);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Payment Type Selector (Segmented Rectangular Chips)
                  Row(
                    children: ['Cash', 'UPI', 'Credit'].map((type) {
                      final selected = billProv.paymentType == type;
                      final label = type == 'Cash'
                          ? loc.t('cash')
                          : type == 'UPI'
                              ? loc.t('upi')
                              : loc.t('credit');
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => billProv.setPaymentType(type),
                            borderRadius: AppRadius.mdAll,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primaryDark : AppColors.background,
                                borderRadius: AppRadius.mdAll,
                                border: Border.all(
                                  color: selected ? AppColors.primaryDark : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Grand total & Save + Share button
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.t('total'), style: AppText.caption),
                          Text(
                            CurrencyFormatter.formatPaise(billProv.grandTotal),
                            style: AppText.amountLarge.copyWith(color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: App3dButton.mint(
                          height: 50,
                          icon: Icons.check_circle_outline,
                          label: '${loc.t("completeAndShareBill")} (${CurrencyFormatter.formatPaise(billProv.grandTotal)})',
                          isLoading: billProv.isSaving,
                          onPressed: billProv.items.isEmpty || billProv.isSaving
                              ? null
                              : () async {
                                  final bill = await billProv.saveBill();
                                  if (bill != null && context.mounted) {
                                    Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => ReceiptScreen(bill: bill)),
                                    );
                                  } else if (billProv.errorMessage != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(billProv.errorMessage!),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
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
        ],
      ),
    );
  }
}
