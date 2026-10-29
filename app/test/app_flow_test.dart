import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('ShopMint Complete Application Flow Tests', () {
    testWidgets('1. Splash screen displays ShopMint branding and tagline', (tester) async {
      await tester.pumpWidget(
        const ShopMintApp(
          home: SplashScreen(autoNavigate: false),
        ),
      );

      expect(find.text('ShopMint'), findsOneWidget);
      expect(find.text('Never Run Out of Stock'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2. Main navigation shell switches between My Shop, Make Bill, and My Sales', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // Top bar check
      expect(find.text('Ramesh Kirana'), findsOneWidget);

      // Verify initial tab is My Shop
      expect(find.text('Stock barcode items'), findsOneWidget);

      // Tap Make Bill tab
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();

      // Verify Make Bill view elements
      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(find.text('Aim at barcode'), findsOneWidget);
      expect(find.text('Loose Item'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);

      // Tap My Sales tab
      await tester.tap(find.text('My Sales'));
      await tester.pumpAndSettle();

      // Verify My Sales view elements
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Sales of day'), findsOneWidget);

      // Tap back to My Shop tab
      await tester.tap(find.text('My Shop'));
      await tester.pumpAndSettle();
      expect(find.text('Stock barcode items'), findsOneWidget);
    });

    testWidgets('3. Complete billing flow: add item via chip, checkout with Cash', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // Navigate to Make Bill
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();

      // Initially bill is empty
      expect(find.text('Bill is empty'), findsOneWidget);

      // Tap the 'Mad' chip to add Mad Angles
      final madChip = find.text('Mad');
      expect(madChip, findsOneWidget);
      await tester.tap(madChip);
      await tester.pumpAndSettle();

      // Bill should now contain Mad Angles
      expect(find.text('Mad Angles'), findsOneWidget);
      expect(find.text('₹20'), findsWidgets);

      // Tap Complete button
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      // Payment modal should appear
      expect(find.text('Complete Bill'), findsOneWidget);
      expect(find.text('Cash Paid'), findsOneWidget);
      expect(find.text('UPI Paid'), findsOneWidget);
      expect(find.text('Mark as Udhaar (Credit)'), findsOneWidget);

      // Tap Cash Paid
      await tester.tap(find.text('Cash Paid'));
      await tester.pumpAndSettle();

      // Should automatically transition to My Sales tab with the new order
      expect(find.text('Sales of day'), findsOneWidget);
    });

    testWidgets('4. Udhaar billing flow: add item, select Udhaar, save customer details', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // Navigate to Make Bill
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();

      // Tap 'uji' chip to add uji coconut water
      final ujiChip = find.text('uji');
      expect(ujiChip, findsOneWidget);
      await tester.tap(ujiChip);
      await tester.pumpAndSettle();

      // Tap Complete button
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      // Select Udhaar mode
      await tester.tap(find.text('Mark as Udhaar (Credit)'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Info for Udhaar'), findsOneWidget);

      // Enter customer name and phone using hint text finders
      final nameField = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText?.contains('Customer Name') ?? false),
      );
      final phoneField = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText?.contains('Phone Number') ?? false),
      );
      expect(nameField, findsOneWidget);
      expect(phoneField, findsOneWidget);

      await tester.enterText(nameField, 'Gupta Ji');
      await tester.enterText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      // Tap Save Udhaar
      await tester.tap(find.text('Save Udhaar'));
      await tester.pumpAndSettle();

      // Should transition to My Sales with Gupta Ji record and confirmation toast
      expect(find.text('Gupta Ji (9876543210)'), findsOneWidget);
      expect(find.text('Bill saved to Udhaar for Gupta Ji'), findsOneWidget);
    });

    testWidgets('5. Loose item addition flow', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // Navigate to Make Bill
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();

      // Tap Loose Item button
      await tester.tap(find.text('Loose Item'));
      await tester.pumpAndSettle();

      // Verify loose items sheet opens
      expect(find.text('Select Loose Item to Add'), findsOneWidget);

      // Tap moong dal from the loose items list
      final moongTile = find.text('moong dal');
      expect(moongTile, findsOneWidget);
      await tester.tap(moongTile);
      await tester.pumpAndSettle();

      // Verify moong dal appears in bill
      expect(find.text('moong dal'), findsOneWidget);
    });

    testWidgets('6. My Shop stock replenishment via modal', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // On My Shop tab, tap Stock barcode items button
      final stockBtn = find.text('Stock barcode items');
      expect(stockBtn, findsOneWidget);
      await tester.tap(stockBtn);
      await tester.pumpAndSettle();

      // Add Stock sheet should be visible
      expect(find.text('Add stock'), findsOneWidget);

      // Tap Add stock
      await tester.tap(find.text('Add stock'));
      await tester.pumpAndSettle();

      // Modal should close and return to My Shop
      expect(find.text('Stock barcode items'), findsOneWidget);
    });

    testWidgets('7. My Sales Udhaar mark paid action', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // Navigate to My Sales
      await tester.tap(find.text('My Sales'));
      await tester.pumpAndSettle();

      // Locate the Paid button for Verma Ji (pre-seeded Udhaar order)
      final paidButtons = find.text('Paid');
      expect(paidButtons, findsWidgets);

      // Scroll into view if needed and tap Paid button
      await tester.ensureVisible(paidButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(paidButtons.first);
      await tester.pumpAndSettle();

      // Verify feedback note
      expect(find.textContaining('marked as paid'), findsOneWidget);
    });

    testWidgets('8. Duplicate scan prevention and inline stepper flow', (tester) async {
      await tester.pumpWidget(const ShopMintApp());
      await tester.pumpAndSettle();

      // Navigate to Make Bill
      await tester.tap(find.text('Make Bill'));
      await tester.pumpAndSettle();

      // Scan/tap Mad Angles the first time
      final madChip = find.text('Mad');
      await tester.tap(madChip);
      await tester.pumpAndSettle();

      // Verify added: 1 item, quantity 1
      expect(find.text('Mad Angles'), findsOneWidget);
      expect(find.byKey(const ValueKey('stepper_qty_8909081007156')), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Now tap/scan Mad Angles a second time (duplicate scan attempt)
      await tester.tap(madChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Should show duplicate warning snackbar with +1 More action
      expect(find.textContaining('Mad Angles already in bill (Qty: 1)'), findsOneWidget);
      expect(find.text('+1 More'), findsOneWidget);
      expect(find.text('Already in bill!'), findsOneWidget);

      // Quantity must NOT have auto-incremented - still 1
      expect(find.text('₹20'), findsWidgets);

      // Tap the +1 More button on the alert snackbar to intentionally add one
      await tester.tap(find.text('+1 More'));
      await tester.pumpAndSettle();

      // Now quantity is 2, total ₹40
      expect(find.text('2'), findsWidgets);
      expect(find.text('₹40'), findsWidgets);

      // Test inline stepper [+] button
      final plusBtn = find.byKey(const ValueKey('stepper_plus_8909081007156'));
      expect(plusBtn, findsOneWidget);
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      // Quantity should now be 3, total ₹60
      expect(find.text('3'), findsWidgets);
      expect(find.text('₹60'), findsWidgets);

      // Test inline stepper [-] button
      final minusBtn = find.byKey(const ValueKey('stepper_minus_8909081007156'));
      expect(minusBtn, findsOneWidget);
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();

      // Quantity should decrease to 2, total ₹40
      expect(find.text('2'), findsWidgets);
      expect(find.text('₹40'), findsWidgets);

      // Test quick remove button
      final removeBtn = find.byKey(const ValueKey('remove_8909081007156'));
      expect(removeBtn, findsOneWidget);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Bill should now be empty
      expect(find.text('Bill is empty'), findsOneWidget);
    });
  });
}
