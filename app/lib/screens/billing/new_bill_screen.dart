import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/shop_mint_components.dart';
import '../khata/add_customer_modal.dart';
import 'barcode_scanner_modal.dart';
import 'receipt_screen.dart';
import 'widgets/loose_item_modal.dart';

class NewBillScreen extends StatefulWidget {
  final List<String>? initialBarcodes;
  final bool isEmbedded;
  final List<ProductModel>? products;
  final Map<String, dynamic>? cart;
  final double? total;
  final String? paymentMode;
  final void Function(ProductModel, [int])? onAdd;
  final void Function(ProductModel, int)? onQty;
  final ValueChanged<String>? onPaymentChanged;
  final VoidCallback? onCheckout;

  const NewBillScreen({
    super.key,
    this.initialBarcodes,
    this.isEmbedded = false,
    this.products,
    this.cart,
    this.total,
    this.paymentMode,
    this.onAdd,
    this.onQty,
    this.onPaymentChanged,
    this.onCheckout,
  });

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final TextEditingController search = TextEditingController();
  String query = '';
  String _selectedPaymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    if (widget.paymentMode != null) {
      _selectedPaymentMode = widget.paymentMode!;
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _showCustomItemDialog(BillingProvider billProv) {
    final name = TextEditingController();
    final price = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(price.text) ?? 0;
              if (name.text.isNotEmpty && value > 0) {
                final customProd = ProductModel(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name.text,
                  unit: '1 item',
                  sellingPrice: (value * 100).toInt(),
                  purchasePrice: 0,
                  currentStock: 99,
                  barcode: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                  color: AppColors.paleMint,
                  icon: Icons.inventory_2_outlined,
                );
                if (widget.onAdd != null) {
                  widget.onAdd!(customProd);
                } else {
                  billProv.addCustomItem(
                    name: name.text,
                    rate: (value * 100).toInt(),
                    qty: 1,
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add to bill'),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelectionDialog(BillingProvider billProv, CustomerProvider custProv) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline, color: AppColors.teal),
                title: const Text('Walk-in Customer'),
                trailing: billProv.selectedCustomer == null
                    ? const Icon(Icons.check, color: AppColors.teal)
                    : null,
                onTap: () {
                  billProv.setCustomer(null);
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              const Divider(),
              if (custProv.customers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No credit customers registered yet', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: custProv.customers.length,
                    separatorBuilder: (_, itemIndex) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final cust = custProv.customers[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(cust.name),
                        subtitle: Text(cust.mobile),
                        onTap: () {
                          billProv.setCustomer(cust);
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newCust = await showModalBottomSheet<CustomerModel>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddCustomerModal(),
              );
              if (newCust != null) {
                billProv.setCustomer(newCust);
                setState(() {});
              }
            },
            child: const Text('Add customer'),
          ),
        ],
      ),
    );
  }

  void _handleScanBarcode(BillingProvider billProv, List<ProductModel> catalog) async {
    final scannedResult = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BarcodeScannerModal(),
    );

    if (scannedResult == null || !mounted) return;

    List<String> codes = [];
    if (scannedResult is List<String>) {
      codes.addAll(scannedResult);
    } else if (scannedResult is String && scannedResult.isNotEmpty) {
      codes.add(scannedResult);
    }

    if (codes.isEmpty) return;

    final prodProv = Provider.of<ProductProvider>(context, listen: false);

    for (final code in codes) {
      final lookup = await prodProv.lookupBarcode(code);
      if (lookup.foundInShop && lookup.existingProduct != null) {
        if (widget.onAdd != null) {
          widget.onAdd!(lookup.existingProduct!);
        } else {
          billProv.addItemFromProduct(lookup.existingProduct!);
        }
      } else {
        final match = catalog.firstWhere((p) => p.barcode == code, orElse: () => catalog.first);
        if (widget.onAdd != null) {
          widget.onAdd!(match);
        } else {
          billProv.addItemFromProduct(match);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProv = Provider.of<BillingProvider>(context);
    final prodProv = Provider.of<ProductProvider>(context);
    final custProv = Provider.of<CustomerProvider>(context);

    final catalog = widget.products ??
        (prodProv.products.isNotEmpty ? prodProv.products : ProductModel.demoProducts);

    final matches = catalog
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.barcode.contains(query))
        .take(4)
        .toList();

    final activeItems = billProv.items;
    final double displayTotal = widget.total ?? (billProv.grandTotal / 100.0);
    final String currentPaymentMode = widget.paymentMode ?? _selectedPaymentMode;

    void onAddProduct(ProductModel p, [int qty = 1]) {
      if (widget.onAdd != null) {
        widget.onAdd!(p, qty);
      } else {
        billProv.addItemFromProduct(p, qty: qty.toDouble());
      }
    }

    void onUpdateQty(ProductModel p, int change) {
      if (widget.onQty != null) {
        widget.onQty!(p, change);
      } else {
        final idx = billProv.items.indexWhere(
          (item) => (item.product?.id == p.id) || (item.name == p.name),
        );
        if (idx >= 0) {
          final newQty = billProv.items[idx].qty + change;
          billProv.updateQuantity(idx, newQty);
        }
      }
    }

    void handleCheckout() async {
      if (widget.onCheckout != null) {
        widget.onCheckout!();
        return;
      }

      if (billProv.items.isEmpty) return;

      final nav = Navigator.of(context);
      final dashProv = Provider.of<DashboardProvider>(context, listen: false);

      billProv.setPaymentType(currentPaymentMode);
      final savedBill = await billProv.saveBill();
      if (savedBill != null && mounted) {
        dashProv.fetchDashboard();
        nav.push(
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(bill: savedBill),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Make Bill',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _handleScanBarcode(billProv, catalog),
                    icon: const Icon(Icons.qr_code_scanner, color: AppColors.teal),
                  ),
                  IconButton(
                    onPressed: () => _showCustomItemDialog(billProv),
                    icon: const Icon(Icons.calculate_outlined, color: AppColors.teal),
                  ),
                  IconButton(
                    onPressed: () => setState(() => billProv.clearCart()),
                    icon: const Icon(Icons.delete_outline, color: AppColors.muted),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 46,
                child: TextField(
                  controller: search,
                  onChanged: (v) => setState(() => query = v),
                  decoration: InputDecoration(
                    hintText: 'Search product or scan barcode',
                    prefixIcon: const Icon(Icons.search, color: AppColors.muted),
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

            // Horizontal Suggestion Chips
            if (query.isNotEmpty && matches.isNotEmpty)
              SizedBox(
                height: 66,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  children: matches
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Icon(p.categoryIcon, size: 17, color: AppColors.teal),
                            label: Text(p.name),
                            onPressed: () {
                              onAddProduct(p);
                              search.clear();
                              setState(() => query = '');
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 12),

            // Quick Chips Bar
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickChip(
                    label: '+ Loose Item',
                    onTap: () => LooseItemModal.show(context, onAdd: onAddProduct),
                  ),
                  _QuickChip(
                    label: '+ Custom Item',
                    onTap: () => _showCustomItemDialog(billProv),
                  ),
                  ...catalog.take(5).map(
                        (p) => _QuickChip(
                          label: p.name.split(' ').first,
                          onTap: () => onAddProduct(p),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Cart Area
            Expanded(
              child: activeItems.isEmpty
                  ? const EmptyCart()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: activeItems.length,
                      separatorBuilder: (_, itemIndex) =>
                          const Divider(height: 1, color: Color(0xFFDDF0ED)),
                      itemBuilder: (context, index) {
                        final item = activeItems[index];
                        final prod = item.product ??
                            ProductModel(
                              id: 'item_$index',
                              name: item.name,
                              unit: item.unit,
                              sellingPrice: item.rate,
                              purchasePrice: 0,
                            );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              ProductThumb(product: prod, size: 44),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '₹${(item.rate / 100).toStringAsFixed(0)} / ${item.unit}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              QtyStepper(
                                value: item.qty.toInt(),
                                onMinus: () => onUpdateQty(prod, -1),
                                onPlus: () => onUpdateQty(prod, 1),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 54,
                                child: Text(
                                  '₹${(item.lineTotal / 100).toStringAsFixed(0)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Dock
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Line
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.teal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          billProv.selectedCustomer != null
                              ? billProv.selectedCustomer!.name
                              : 'Walk-in Customer',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showCustomerSelectionDialog(billProv, custProv),
                        child: const Text('Change'),
                      ),
                    ],
                  ),

                  // Payment Mode Choice Pills
                  Row(
                    children: ['Cash', 'UPI', 'Credit']
                        .map(
                          (mode) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: _PaymentChoice(
                                label: mode == 'Credit' ? 'Credit (Udhaar)' : mode,
                                selected: currentPaymentMode == mode,
                                onTap: () {
                                  if (widget.onPaymentChanged != null) {
                                    widget.onPaymentChanged!(mode);
                                  } else {
                                    setState(() => _selectedPaymentMode = mode);
                                    billProv.setPaymentType(mode);
                                  }
                                },
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Total & 3D Action Button
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              letterSpacing: .8,
                            ),
                          ),
                          Text(
                            '₹${displayTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: App3dButton(
                          label: 'COMPLETE & SHARE BILL  (₹${displayTotal.toStringAsFixed(0)})',
                          icon: Icons.check,
                          onPressed: activeItems.isEmpty ? null : handleCheckout,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onTap,
          side: const BorderSide(color: AppColors.border),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 30, height: 32),
              padding: EdgeInsets.zero,
              onPressed: onMinus,
              icon: const Icon(Icons.remove, size: 16, color: AppColors.teal),
            ),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 30, height: 32),
              padding: EdgeInsets.zero,
              onPressed: onPlus,
              icon: const Icon(Icons.add, size: 16, color: AppColors.teal),
            ),
          ],
        ),
      );
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.paleMint : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.mint : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppColors.teal : AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.paleMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.teal,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your bill is empty',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            const Text(
              'Search or tap a frequent item to get started',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      );
}
