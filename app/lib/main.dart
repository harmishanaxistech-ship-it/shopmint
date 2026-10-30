import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/localization/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/product_provider.dart';
import 'models/shop_mint_models.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/splash_screen.dart';
import 'widgets/shop_mint_components.dart';

export 'screens/main_navigation_shell.dart';
export 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ShopMintApp(home: SplashScreen()));
}

class ShopMintApp extends StatelessWidget {
  final Widget? home;
  final List<ProductItem>? initialProducts;
  final List<OrderRecord>? initialOrders;

  const ShopMintApp({
    super.key,
    this.home,
    this.initialProducts,
    this.initialOrders,
  });

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CustomerProvider()),
          ChangeNotifierProvider(create: (_) => BillingProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ],
        child: MaterialApp(
          title: 'ShopMint',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: canvas,
            colorScheme: ColorScheme.fromSeed(seedColor: mint, primary: teal),
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: ink,
              elevation: 0,
              centerTitle: false,
            ),
          ),
          home: home ??
              ShopMintShell(
                initialProducts: initialProducts,
                initialOrders: initialOrders,
              ),
        ),
      );
}
