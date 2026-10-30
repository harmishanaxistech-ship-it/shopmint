import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';
import 'package:app/models/shop_mint_models.dart';
import 'package:app/screens/billing/make_bill_tab.dart';
import 'test_fixtures.dart';

Widget _buildTestApp({List<ProductItem>? products, List<OrderRecord>? orders}) {
  final prods = products ?? testProducts;
  return ShopMintApp(
    initialProducts: prods,
    initialOrders: orders ?? createTestOrders(prods),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Product Management and Image Display Tests', () {
    testWidgets('0. Clean startup without test fixtures starts with 0 products and empty state', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      expect(find.text('Shop items: 0'), findsOneWidget);
      expect(find.text('No products in shop yet'), findsOneWidget);
    });

    testWidgets('1. My Shop displays product listing with Edit and Delete action buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verify My Shop listing is shown
      expect(find.text('Shop items: 8'), findsOneWidget);
      expect(find.text('Mad Angles'), findsOneWidget);
      expect(find.text('uji coconut water'), findsOneWidget);

      // Verify Edit and Delete buttons exist on product items
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
      expect(find.text('Add Product'), findsOneWidget);
      expect(find.text('Stock barcode items'), findsOneWidget);
    });

    testWidgets('2. Tapping Edit button opens Edit Product modal with live image preview and allows saving', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Find first Edit button and tap it
      final editButtons = find.byIcon(Icons.edit_outlined);
      expect(editButtons, findsWidgets);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Verify Edit Product modal opened
      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('Product Name'), findsOneWidget);
      expect(find.text('Selling Price (₹)'), findsOneWidget);
      expect(find.text('Product Image URL'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Modal dismissed
      expect(find.text('Edit Product'), findsNothing);
    });

    testWidgets('3. Tapping Delete button shows confirmation dialog and cancels or confirms', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap Delete icon of first item
      final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Confirmation dialog displayed
      expect(find.text('Delete Product'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Item still exists
      expect(find.text('Mad Angles'), findsOneWidget);
    });

    testWidgets('4. Add Product modal in My Shop shows image preview and adds new product', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap Add Product button
      await tester.tap(find.text('Add Product'));
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Add New Product'), findsOneWidget);
      expect(find.text('Product Image URL (optional)'), findsOneWidget);
      expect(find.text('Save Product'), findsOneWidget);

      // Enter name and price
      await tester.enterText(find.widgetWithText(TextField, 'Product Name (e.g. Tata Salt)'), 'Tata Tea Gold');
      await tester.enterText(find.widgetWithText(TextField, 'Price (₹)'), '140');

      // Tap Save Product
      await tester.tap(find.text('Save Product'));
      await tester.pumpAndSettle();

      // Modal closed and product appears in list
      expect(find.text('Add New Product'), findsNothing);
      expect(find.text('Tata Tea Gold'), findsOneWidget);
    });

    testWidgets('5. Make Bill add barcode modal displays image preview and preset image options', (tester) async {
      ProductItem? addedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showAddNewBarcodeProductModal(
                    ctx,
                    barcode: '8901234567890',
                    initialName: 'Good Day Butter',
                    initialImage: 'https://images.openfoodfacts.org/images/products/890/171/910/1018/front_en.3.400.jpg',
                    isMasterFound: true,
                    onAdded: (item) => addedItem = item,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Tap to open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify modal elements
      expect(find.text('Product Recognized!'), findsOneWidget);
      expect(find.text('Product Image URL (optional)'), findsOneWidget);
      expect(find.text('Save and Add to Bill'), findsOneWidget);
      expect(find.text('Good Day Butter'), findsOneWidget);

      // Enter selling price
      await tester.enterText(find.widgetWithText(TextField, 'Price (₹)'), '30');

      // Tap Save and Add to Bill
      await tester.tap(find.text('Save and Add to Bill'));
      await tester.pumpAndSettle();

      expect(addedItem, isNotNull);
      expect(addedItem?.name, 'Good Day Butter');
      expect(addedItem?.price, 30);
    });

    testWidgets('6. Main Navigation Shell active tab highlight styling', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Initial tab is My Shop, label should have active font weight
      final myShopText = tester.widget<Text>(find.text('My Shop'));
      expect(myShopText.style?.fontWeight, FontWeight.w800);

      // Switch to Make Bill
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();

      final makeBillText = tester.widget<Text>(find.text('Make Bill'));
      expect(makeBillText.style?.fontWeight, FontWeight.w800);

      // Switch to My Sales
      await tester.tap(find.text('My Sales'));
      await tester.pumpAndSettle();

      final mySalesText = tester.widget<Text>(find.text('My Sales'));
      expect(mySalesText.style?.fontWeight, FontWeight.w800);
    });

    testWidgets('7. Edit and Add product modals render without overflow on narrow 320px screens', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Open Edit modal on narrow screen
      final editButtons = find.byIcon(Icons.edit_outlined);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Check chips render and modal is responsive without errors
      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('piece'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Open Add Product modal on narrow screen
      await tester.tap(find.text('Add Product'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Product'), findsOneWidget);
      expect(find.text('piece'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Navigate to Make Bill on narrow screen to verify scanner top bar and controls don't overflow
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();
      expect(find.text('Scan Barcode'), findsOneWidget);
    });

    testWidgets('8. MakeBillTab respects isActive flag and disables scanner outside Make Bill tab', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // On launch, we are on My Shop (tab 0)
      expect(find.text('Shop items: 8'), findsOneWidget);

      // Verify MakeBillTab widget is rendered with isActive == false while offstage
      final makeBillTabFinder = find.byType(MakeBillTab, skipOffstage: false);
      expect(makeBillTabFinder, findsOneWidget);
      final makeBillTabWidget = tester.widget<MakeBillTab>(makeBillTabFinder);
      expect(makeBillTabWidget.isActive, false);

      // Tap on Make Bill tab
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();

      // Verify MakeBillTab widget is now active with isActive == true on-stage
      expect(find.byType(MakeBillTab), findsOneWidget);
      final activeMakeBillTab = tester.widget<MakeBillTab>(find.byType(MakeBillTab));
      expect(activeMakeBillTab.isActive, true);
    });

    testWidgets('9. Scanned product popup displays product info and adds with quantity', (tester) async {
      final testProduct = ProductItem(
        name: 'Tata Salt 1kg',
        pack: 'packet',
        price: 28,
        stock: 50,
        barcode: '8901030383748',
        imageUrl: '',
        profit: 4,
      );
      ProductItem? addedProduct;
      int addedQty = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showScannedProductModal(
                    context: ctx,
                    product: testProduct,
                    currentBillQty: 0,
                    onAdd: (p, q) {
                      addedProduct = p;
                      addedQty = q;
                    },
                  );
                },
                child: const Text('Open Scanned Modal'),
              ),
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Scanned Modal'));
      await tester.pumpAndSettle();

      // Verify product popup details
      expect(find.text('Product Scanned'), findsOneWidget);
      expect(find.text('Tata Salt 1kg'), findsOneWidget);
      expect(find.text('8901030383748'), findsOneWidget);
      expect(find.text('₹28'), findsWidgets);
      expect(find.text('Stock: 50'), findsOneWidget);
      expect(find.text('Quantity to Add'), findsOneWidget);

      // Increase quantity using '+2' chip
      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
      expect(find.text('₹56'), findsWidgets);

      // Tap Add to Bill
      await tester.tap(find.text('Add to Bill • ₹56'));
      await tester.pumpAndSettle();

      expect(addedProduct?.name, 'Tata Salt 1kg');
      expect(addedQty, 2);
    });

    testWidgets('10. Pending low-stock tab filters inventory items in My Shop', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Check initial shop items tab is selected
      expect(find.text('Shop items: 8'), findsOneWidget);
      expect(find.text('Mad Angles'), findsOneWidget);

      // Tap on Pending tab (low stock items)
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      // Peanut butter has stock 3 (<= 5), so it should be visible in Pending
      expect(find.text('Peanut butter'), findsOneWidget);

      // Tap back to Shop items
      await tester.tap(find.text('Shop items: 8'));
      await tester.pumpAndSettle();
      expect(find.text('Mad Angles'), findsOneWidget);
    });

    testWidgets('11. Settings button opens Settings screen with Language, Privacy Policy, and Terms', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Find and tap the settings icon on top bar
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Verify Settings screen elements
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);

      // Tap Privacy Policy
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('ShopMint Privacy Policy'), findsOneWidget);

      // Go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Tap Terms & Conditions
      await tester.tap(find.text('Terms & Conditions'));
      await tester.pumpAndSettle();
      expect(find.text('ShopMint Terms of Service'), findsOneWidget);
    });

    testWidgets('12. Receipt action in My Sales displays itemized receipt dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to My Sales
      await tester.tap(find.text('My Sales'));
      await tester.pumpAndSettle();

      // Find Receipt button on orders
      final receiptButtons = find.text('Receipt');
      expect(receiptButtons, findsWidgets);

      // Tap the first Receipt button
      await tester.tap(receiptButtons.first);
      await tester.pumpAndSettle();

      // Verify receipt dialog
      expect(find.text('Bill Receipt'), findsOneWidget);
      expect(find.text('Share Receipt'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('13. My Shop pull-to-refresh triggers RefreshIndicator and reloads inventory', (tester) async {
      bool refreshed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyShopTab(
              products: testProducts,
              storeName: 'Test Store',
              onStockUpdated: () {},
              onScanRequested: () {},
              onRefresh: () async {
                refreshed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger RefreshIndicator via show()
      expect(find.byType(RefreshIndicator), findsOneWidget);
      final future = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      await future;
      await tester.pump(const Duration(milliseconds: 300));

      expect(refreshed, isTrue);
    });
  });
}
