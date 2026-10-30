import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/storage/master_catalog_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/receipt_share_helper.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../models/shop_mint_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/shop_mint_components.dart';
import 'billing/make_bill_tab.dart';
import 'sales/my_sales_tab.dart';
import 'shop/my_shop_tab.dart';

export '../../widgets/app_3d_button.dart' show Vanik3DButton, VanikButtonVariant;
export 'billing/make_bill_tab.dart' show MakeBillTab;
export 'sales/my_sales_tab.dart' show MySalesTab;
export 'shop/my_shop_tab.dart' show MyShopTab;

class MainNavigationShell extends StatelessWidget {
  final List<ProductItem>? initialProducts;
  final List<OrderRecord>? initialOrders;

  const MainNavigationShell({
    super.key,
    this.initialProducts,
    this.initialOrders,
  });

  @override
  Widget build(BuildContext context) {
    return ShopMintShell(
      initialProducts: initialProducts,
      initialOrders: initialOrders,
    );
  }
}

class ShopMintShell extends StatefulWidget {
  final List<ProductItem>? initialProducts;
  final List<OrderRecord>? initialOrders;

  const ShopMintShell({
    super.key,
    this.initialProducts,
    this.initialOrders,
  });

  @override
  State<ShopMintShell> createState() => _ShopMintShellState();
}

class _ShopMintShellState extends State<ShopMintShell> {
  int _tab = 0;
  final StorageService _storage = StorageService();
  final Map<String, BillLine> _bill = {};
  late List<ProductItem> _products = widget.initialProducts != null
      ? List.from(widget.initialProducts!)
      : List.from(initialProducts);
  late final List<OrderRecord> _orders = widget.initialOrders != null
      ? List.from(widget.initialOrders!)
      : [];

  String get _storeName {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user?.shopName != null && user!.shopName.isNotEmpty) {
        return user.shopName;
      }
    } catch (_) {}
    return 'Ramesh Kirana';
  }

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
  }

  Future<void> _loadInitialProducts() async {
    try {
      final cached = await _storage.loadLocalProducts();
      final cachedOrders = await _storage.loadLocalOrders();
      if (mounted) {
        setState(() {
          if (cached != null && cached.isNotEmpty && widget.initialProducts == null) {
            _products = cached;
          }
          if (cachedOrders != null && cachedOrders.isNotEmpty && widget.initialOrders == null) {
            final realOrders = cachedOrders
                .where((o) => !(o.customerName == 'Verma Ji' && o.time == '22:31'))
                .toList();
            _orders.clear();
            _orders.addAll(realOrders);
          }
        });
      }
    } catch (_) {}
    _syncLiveDatabase();
  }

  Future<void> _handleRefresh() async {
    await _loadInitialProducts();
  }

  Future<void> _syncLiveDatabase() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final prodProv = Provider.of<ProductProvider>(context, listen: false);
      final custProv = Provider.of<CustomerProvider>(context, listen: false);
      final dashProv = Provider.of<DashboardProvider>(context, listen: false);

      if (!auth.isAuthenticated) {
        await auth.loginAsDemo();
      }

      await Future.wait([
        dashProv.fetchDashboard(),
        custProv.fetchCustomers(),
        prodProv.fetchProducts(),
      ]);

      if (mounted) {
        setState(() {
          if (prodProv.products.isNotEmpty) {
            _products = prodProv.products.map((p) {
              return ProductItem(
                name: p.name,
                pack: p.unit.isNotEmpty ? p.unit : 'piece',
                price: p.price,
                stock: p.currentStock.toInt(),
                barcode: p.barcode.trim(),
                imageUrl: p.imageUrl,
                profit: (p.price - (p.purchasePrice / 100.0)).clamp(0, 99999),
                soldCount: 0,
              );
            }).toList();
          }

          // If backend has bills and local orders are empty or defaults, sync server bills
          if (dashProv.salesBills.isNotEmpty) {
            for (final sb in dashProv.salesBills) {
              final alreadyExists = _orders.any((o) => o.billNo == sb.billNo);
              if (!alreadyExists) {
                final dateStr = '${sb.createdAt.year}-${sb.createdAt.month.toString().padLeft(2, '0')}-${sb.createdAt.day.toString().padLeft(2, '0')}';
                final timeStr = '${sb.createdAt.hour.toString().padLeft(2, '0')}:${sb.createdAt.minute.toString().padLeft(2, '0')}';
                final billLines = sb.items.map((it) {
                  return BillLine(
                    ProductItem(
                      name: it.name,
                      pack: it.unit,
                      price: it.rate / 100.0,
                      stock: 10,
                      imageUrl: it.imageUrl,
                    ),
                    it.qty.toInt(),
                  );
                }).toList();

                _orders.add(
                  OrderRecord(
                    time: timeStr,
                    date: dateStr,
                    billNo: sb.billNo,
                    items: billLines,
                    total: sb.grandTotal / 100.0,
                    profit: sb.totalProfit / 100.0,
                    isUdhaar: sb.balanceDue > 0,
                    customerName: sb.customerName,
                    customerPhone: sb.customerPhone,
                    isPaid: sb.balanceDue == 0,
                  ),
                );
              }
            }
          }
        });
        await _storage.saveLocalProducts(_products);
        await _storage.saveLocalOrders(_orders);
      }
    } catch (_) {}
  }

  void _addNewProduct(ProductItem item) {
    setState(() {
      final existingIndex = _products.indexWhere(
        (p) => item.barcode.isNotEmpty && isBarcodeMatch(p.barcode, item.barcode),
      );
      if (existingIndex >= 0) {
        _products[existingIndex] = item;
      } else {
        _products.insert(0, item);
      }
    });

    _storage.saveLocalProducts(_products);

    if (item.barcode.isNotEmpty) {
      MasterCatalogService.saveToMaster(MasterProductItem(
        barcode: item.barcode,
        name: item.name,
        image: item.imageUrl,
        unit: item.pack,
      ));
    }

    try {
      final prodProv = Provider.of<ProductProvider>(context, listen: false);
      prodProv.createProduct(
        name: item.name,
        barcode: item.barcode,
        purchasePrice: ((item.price - item.profit) * 100).toInt(),
        sellingPrice: (item.price * 100).toInt(),
        currentStock: item.stock.toDouble(),
        unit: item.pack == 'piece' ? 'pcs' : item.pack,
        imageUrl: item.imageUrl,
      ).then((_) {
        _storage.saveLocalProducts(_products);
      });
    } catch (_) {}
  }

  void _onProductUpdated(ProductItem item) {
    setState(() {
      final idx = _products.indexWhere(
        (p) => (item.barcode.isNotEmpty && isBarcodeMatch(p.barcode, item.barcode)) || p.name == item.name,
      );
      if (idx >= 0) {
        _products[idx] = item;
      }

      for (final entry in _bill.entries) {
        if (isBarcodeMatch(entry.key, item.barcode) ||
            isBarcodeMatch(entry.value.product.barcode, item.barcode) ||
            entry.value.product.name == item.name) {
          entry.value.product.name = item.name;
          entry.value.product.price = item.price;
          entry.value.product.stock = item.stock;
          entry.value.product.pack = item.pack;
          entry.value.product.imageUrl = item.imageUrl;
          entry.value.product.barcode = item.barcode;
        }
      }
    });

    _storage.saveLocalProducts(_products);

    if (item.barcode.isNotEmpty) {
      MasterCatalogService.saveToMaster(MasterProductItem(
        barcode: item.barcode,
        name: item.name,
        image: item.imageUrl,
        unit: item.pack,
      ));
    }

    try {
      final prodProv = Provider.of<ProductProvider>(context, listen: false);
      final match = prodProv.products.firstWhere(
        (p) => (item.barcode.isNotEmpty && isBarcodeMatch(p.barcode, item.barcode)) || p.name == item.name,
        orElse: () => ProductModel(id: '', name: '', purchasePrice: 0, sellingPrice: 0),
      );
      if (match.id.isNotEmpty) {
        prodProv.updateProduct(
          productId: match.id,
          name: item.name,
          barcode: item.barcode,
          unit: item.pack == 'piece' ? 'pcs' : item.pack,
          sellingPrice: (item.price * 100).toInt(),
          imageUrl: item.imageUrl,
        ).then((_) {
          _storage.saveLocalProducts(_products);
        });
      }
    } catch (_) {}
  }

  void _onProductDeleted(ProductItem item) {
    setState(() {
      _products.removeWhere(
        (p) => (item.barcode.isNotEmpty && isBarcodeMatch(p.barcode, item.barcode)) || p.name == item.name,
      );

      _bill.removeWhere(
        (key, value) =>
            (item.barcode.isNotEmpty && isBarcodeMatch(key, item.barcode)) ||
            isBarcodeMatch(value.product.barcode, item.barcode) ||
            value.product.name == item.name,
      );
    });

    _storage.saveLocalProducts(_products);

    try {
      final prodProv = Provider.of<ProductProvider>(context, listen: false);
      final match = prodProv.products.firstWhere(
        (p) => (item.barcode.isNotEmpty && isBarcodeMatch(p.barcode, item.barcode)) || p.name == item.name,
        orElse: () => ProductModel(id: '', name: '', purchasePrice: 0, sellingPrice: 0),
      );
      if (match.id.isNotEmpty) {
        prodProv.deleteProduct(match.id).then((_) {
          _storage.saveLocalProducts(_products);
        });
      }
    } catch (_) {}
  }

  double get _billTotal => _bill.values.fold(0, (sum, line) => sum + line.total);

  void _addToBill(ProductItem item, [int qty = 1]) {
    setState(() {
      String? matchedKey;
      for (final key in _bill.keys) {
        if (isBarcodeMatch(key, item.barcode)) {
          matchedKey = key;
          break;
        }
      }
      final keyToUse = matchedKey ?? item.barcode;
      final existing = _bill[keyToUse];
      if (existing == null) {
        _bill[keyToUse] = BillLine(item, qty);
      } else {
        existing.qty += qty;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _updateBillQty(ProductItem item, int delta) {
    setState(() {
      String? matchedKey;
      for (final key in _bill.keys) {
        if (isBarcodeMatch(key, item.barcode)) {
          matchedKey = key;
          break;
        }
      }
      final keyToUse = matchedKey ?? item.barcode;
      final existing = _bill[keyToUse];
      if (existing == null) return;
      existing.qty += delta;
      if (existing.qty <= 0) {
        _bill.remove(keyToUse);
      }
    });
  }

  void _removeBillLine(String barcode) {
    setState(() {
      _bill.removeWhere((key, value) => isBarcodeMatch(key, barcode) || isBarcodeMatch(value.product.barcode, barcode));
    });
  }

  Future<void> _completeBill({required bool isUdhaar, String? customerName, String? phone}) async {
    if (_bill.isEmpty) return;

    final lines = _bill.values.map((l) => BillLine(l.product, l.qty)).toList();
    final total = _billTotal;
    double orderProfit = 0;

    for (final line in lines) {
      line.product.stock = (line.product.stock - line.qty).clamp(0, 999999);
      line.product.soldCount += line.qty;
      orderProfit += line.product.profit * line.qty;
    }

    final now = DateTime.now();
    final newOrder = OrderRecord(
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      items: lines,
      total: total,
      profit: orderProfit,
      isUdhaar: isUdhaar,
      customerName: customerName,
      customerPhone: phone,
    );

    setState(() {
      _orders.insert(0, newOrder);
      _bill.clear();
      _tab = 2; // Jump to My Sales
    });

    _storage.saveLocalOrders(_orders);

    showNote(
      context,
      isUdhaar ? 'Bill saved to Udhaar for $customerName' : 'Bill completed! Total: ₹${total.toStringAsFixed(0)}',
      actionLabel: 'Share Receipt',
      onAction: () {
        ReceiptShareHelper.shareOrderReceipt(newOrder, shopName: _storeName);
      },
    );

    // Save to real database
    try {
      final billProv = Provider.of<BillingProvider>(context, listen: false);
      final custProv = Provider.of<CustomerProvider>(context, listen: false);
      final prodProv = Provider.of<ProductProvider>(context, listen: false);
      final dashProv = Provider.of<DashboardProvider>(context, listen: false);

      billProv.clearCart();
      for (final l in lines) {
        final match = prodProv.products.firstWhere(
          (p) => p.barcode == l.product.barcode || p.name == l.product.name,
          orElse: () => ProductModel(
            id: '',
            name: l.product.name,
            purchasePrice: 0,
            sellingPrice: (l.product.price * 100).toInt(),
          ),
        );
        if (match.id.isNotEmpty) {
          billProv.addItemFromProduct(match, qty: l.qty.toDouble());
        } else {
          billProv.addCustomItem(
            name: l.product.name,
            rate: (l.product.price * 100).toInt(),
            qty: l.qty.toDouble(),
            unit: l.product.pack,
          );
        }
      }

      if (isUdhaar && customerName != null && customerName.trim().isNotEmpty) {
        final cleanName = customerName.trim();
        final cleanPhone = (phone ?? '').trim();
        CustomerModel? customerToUse;

        for (final c in custProv.customers) {
          if ((cleanPhone.isNotEmpty && c.mobile == cleanPhone) ||
              (c.name.toLowerCase() == cleanName.toLowerCase())) {
            customerToUse = c;
            break;
          }
        }

        if (customerToUse == null) {
          try {
            customerToUse = await custProv.createCustomer(
              name: cleanName,
              mobile: cleanPhone,
            );
          } catch (_) {}
        }

        customerToUse ??= CustomerModel(
          id: '',
          name: cleanName,
          mobile: cleanPhone,
          balance: 0,
        );

        billProv.setCustomer(customerToUse);
        billProv.setPaymentType('Credit');
      } else {
        billProv.setPaymentType('Cash');
      }

      final savedBill = await billProv.saveBill();
      if (savedBill != null) {
        newOrder.billNo = savedBill.billNo;
        _storage.saveLocalOrders(_orders);
      }
      await Future.wait([
        dashProv.fetchDashboard(),
        custProv.fetchCustomers(),
        prodProv.fetchProducts(),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      MyShopTab(
        products: _products,
        storeName: _storeName,
        onStockUpdated: () {
          setState(() {});
          _storage.saveLocalProducts(_products);
        },
        onScanRequested: () => setState(() => _tab = 1),
        onProductUpdated: _onProductUpdated,
        onProductDeleted: _onProductDeleted,
        onProductAdded: _addNewProduct,
        onRefresh: _handleRefresh,
      ),
      MakeBillTab(
        isActive: _tab == 1,
        products: _products,
        bill: _bill,
        total: _billTotal,
        onAdd: _addToBill,
        onQty: _updateBillQty,
        onRemove: _removeBillLine,
        onClear: () => setState(_bill.clear),
        onCheckout: (isUdhaar, name, phone) => _completeBill(isUdhaar: isUdhaar, customerName: name, phone: phone),
        onAddProduct: _addNewProduct,
        onEditProduct: (item) {
          showEditProductModal(
            context: context,
            item: item,
            onUpdated: _onProductUpdated,
            onDeleted: () => _onProductDeleted(item),
          );
        },
      ),
      MySalesTab(
        orders: _orders,
        products: _products,
        storeName: _storeName,
        onOrdersChanged: () {
          setState(() {});
          _storage.saveLocalOrders(_orders);
        },
        onRefresh: _handleRefresh,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            height: 74,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: line, width: 1.0)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A0F766E),
                  blurRadius: 8,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _VanikBottomNavItem(
                    iconWidget: const StorefrontArtwork(size: 22),
                    label: 'My Shop',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                Expanded(
                  child: _VanikMakeBillNavButton(
                    selected: _tab == 1,
                    itemCount: _bill.values.fold(0, (s, l) => s + l.qty),
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
                Expanded(
                  child: _VanikBottomNavItem(
                    iconWidget: const WalletArtwork(size: 22),
                    label: 'My Sales',
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VanikBottomNavItem extends StatelessWidget {
  const _VanikBottomNavItem({
    required this.iconWidget,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget iconWidget;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 28 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: selected ? teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? mintTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFF99F6E4) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: selected ? 1.0 : 0.55,
                      child: iconWidget,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: selected ? 11.5 : 10.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? teal : muted,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VanikMakeBillNavButton extends StatelessWidget {
  const _VanikMakeBillNavButton({
    required this.selected,
    required this.itemCount,
    required this.onTap,
  });

  final bool selected;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 28 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: selected ? teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? mintTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFF99F6E4) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: selected
                              ? const [brightTeal, teal]
                              : const [Color(0xFF0D9488), Color(0xFF115E59)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? const Color(0xFF5EEAD4) : Colors.transparent,
                          width: selected ? 1.5 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selected ? const Color(0x3D0F766E) : const Color(0x1F000000),
                            blurRadius: selected ? 5 : 2,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const PrinterArtwork(size: 18),
                          if (itemCount > 0)
                            Positioned(
                              top: 1,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x22000000), blurRadius: 2),
                                  ],
                                ),
                                child: Text(
                                  '$itemCount',
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: teal),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Make Bill',
                      style: TextStyle(
                        fontSize: selected ? 11.5 : 10.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? teal : muted,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
