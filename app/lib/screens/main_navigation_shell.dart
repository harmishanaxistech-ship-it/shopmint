import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/locale_provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/product_provider.dart';
import 'billing/new_bill_screen.dart';
import 'dashboard/dashboard_tab.dart';
import 'sales/sales_tab.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }

  final List<Widget> _tabs = const [
    DashboardTab(),
    NewBillScreen(isEmbedded: true),
    SalesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySurface,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront, color: AppColors.primaryDark),
              label: loc.t('tabMyShop'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long, color: AppColors.primaryDark),
              label: loc.t('makeBill'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart, color: AppColors.primaryDark),
              label: loc.t('tabMySales'),
            ),
          ],
        ),
      ),
    );
  }
}
