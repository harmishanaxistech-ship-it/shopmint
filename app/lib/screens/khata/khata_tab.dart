import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/customer_provider.dart';
import 'add_customer_modal.dart';
import 'customer_ledger_screen.dart';

class KhataTab extends StatefulWidget {
  const KhataTab({super.key});

  @override
  State<KhataTab> createState() => _KhataTabState();
}

class _KhataTabState extends State<KhataTab> {
  final _searchController = TextEditingController();
  bool _filterHasBalance = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final custProv = Provider.of<CustomerProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => custProv.fetchCustomers(
          search: _searchController.text.trim(),
          hasBalance: _filterHasBalance,
        ),
        child: Column(
          children: [
            // Top Summary Outstanding Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.t('totalUdhaar'), style: AppText.caption),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatPaise(custProv.totalOutstanding),
                        style: AppText.amountLarge.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      '${custProv.countWithBalance} ${loc.t('customers')}',
                      style: AppText.label.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: loc.t('searchCustomerHint'),
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (val) {
                        custProv.fetchCustomers(search: val.trim(), hasBalance: _filterHasBalance);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(loc.t('hasUdhaar')),
                    selected: _filterHasBalance,
                    onSelected: (val) {
                      setState(() => _filterHasBalance = val);
                      custProv.fetchCustomers(search: _searchController.text.trim(), hasBalance: val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Customer List
            Expanded(
              child: custProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : custProv.customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 48, color: AppColors.textDisabled),
                              const SizedBox(height: 12),
                              Text(loc.t('noCustomers'), style: AppText.body),
                              const SizedBox(height: 4),
                              Text(loc.t('addCustomerHint'), style: AppText.caption),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: custProv.customers.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final c = custProv.customers[idx];
                            return Card(
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerLedgerScreen(customer: c),
                                    ),
                                  );
                                },
                                title: Text(c.name, style: AppText.bodyLarge),
                                subtitle: Text(
                                  c.mobile.isNotEmpty ? c.mobile : '',
                                  style: AppText.caption,
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatPaise(c.balance),
                                      style: AppText.amount.copyWith(
                                        color: c.balance > 0 ? AppColors.error : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (c.balance > 0)
                                      Text(
                                        loc.t('pendingUdhaar'),
                                        style: AppText.caption.copyWith(color: AppColors.error),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'khata_fab',
        tooltip: loc.t('addCustomer'),
        child: const Icon(Icons.person_add_alt_1),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddCustomerModal(),
          );
        },
      ),
    );
  }
}
