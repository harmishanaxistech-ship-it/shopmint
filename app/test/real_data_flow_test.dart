import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';
import 'package:app/screens/auth/pin_login_screen.dart';
import 'package:app/screens/auth/quick_register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Real Data Authentication & Navigation Flow Tests', () {
    testWidgets('1. PinLoginScreen renders ShopMint branding and inputs', (tester) async {
      await tester.pumpWidget(
        const ShopMintApp(
          home: PinLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shopkeeper Login'), findsOneWidget);
      expect(find.text('Enter your registered mobile & 4-digit PIN'), findsOneWidget);
      expect(find.text('Login to Store'), findsOneWidget);
      expect(find.text('Register New Store'), findsOneWidget);
      expect(find.text('Continue to Demo Store'), findsOneWidget);

      // Enter mobile and PIN
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.at(0), '9876543210');
      await tester.enterText(textFields.at(1), '1234');
      await tester.pumpAndSettle();
    });

    testWidgets('2. PinLoginScreen demo store bypass navigates to MainNavigationShell', (tester) async {
      await tester.pumpWidget(
        const ShopMintApp(
          home: PinLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Continue to Demo Store
      await tester.tap(find.text('Continue to Demo Store'));
      await tester.pumpAndSettle();

      // Should land on MainNavigationShell with Ramesh Kirana
      expect(find.text('Ramesh Kirana'), findsOneWidget);
      expect(find.text('Stock barcode items'), findsOneWidget);
    });

    testWidgets('3. QuickRegisterScreen renders all registration fields', (tester) async {
      await tester.pumpWidget(
        const ShopMintApp(
          home: QuickRegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Your Kirana Account'), findsOneWidget);
      expect(find.text('Shop / Store Name'), findsOneWidget);
      expect(find.text('Owner / Your Name'), findsOneWidget);
      expect(find.text('Create & Open Store'), findsOneWidget);

      // Enter shop and owner details
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));
      await tester.enterText(fields.at(0), 'Shree Ram Kirana Store');
      await tester.enterText(fields.at(1), 'Ramesh Patel');
      await tester.enterText(fields.at(2), '9820001122');
      await tester.enterText(fields.at(3), '1234');
      await tester.pumpAndSettle();

      expect(find.text('Shree Ram Kirana Store'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
    });
  });
}

