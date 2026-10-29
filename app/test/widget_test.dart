import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopMintApp());
    expect(find.text('Ramesh Kirana'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
