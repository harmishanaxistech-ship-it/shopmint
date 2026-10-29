import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';
import 'package:app/models/shop_mint_models.dart';
import 'package:app/screens/billing/make_bill_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Product Management and Image Display Tests', () {
    testWidgets('1. My Shop displays product listing with Edit and Delete action buttons', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
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
      await tester.pumpWidget(const ShopMintApp());
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
      await tester.pumpWidget(const ShopMintApp());
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
      await tester.pumpWidget(const ShopMintApp());
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

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check image and catalog match
      expect(find.text('Product Recognized!'), findsOneWidget);
      expect(find.text('Master FMCG Catalog Match'), findsOneWidget);
      expect(find.text('Product Image URL (optional)'), findsOneWidget);
      expect(find.text('Save and Add to Bill'), findsOneWidget);

      // Save and add
      await tester.tap(find.text('Save and Add to Bill'));
      await tester.pumpAndSettle();

      expect(addedItem, isNotNull);
      expect(addedItem!.name, 'Good Day Butter');
      expect(addedItem!.imageUrl, isNotEmpty);
    });

    testWidgets('6. Bottom navigation bar highlights selected page with active indicator and background badge', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // Check My Shop is initially selected
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

      await tester.pumpWidget(const ShopMintApp());
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
      await tester.pumpWidget(const ShopMintApp());
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
  });
}
