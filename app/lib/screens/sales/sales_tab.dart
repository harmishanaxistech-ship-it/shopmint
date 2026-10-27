import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/bill_model.dart';
import '../dashboard/widgets/sales_analytics_chart.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  final ApiClient _client = ApiClient();
  bool _isLoading = true;

  int _totalBilled = 0;
  int _cashReceived = 0;
  int _upiReceived = 0;
  int _creditGiven = 0;
  int _totalBills = 0;
  int _grossProfit = 0;
  List<Map<String, dynamic>> _bestSellers = [];
  List<BillModel> _bills = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final salesRes = await _client.dio.get(ApiConstants.sales);
      if (salesRes.statusCode == 200 && salesRes.data['success'] == true) {
        _totalBilled = salesRes.data['totalBilled'] ?? 0;
        _cashReceived = salesRes.data['cashReceived'] ?? 0;
        _upiReceived = salesRes.data['upiReceived'] ?? 0;
        _creditGiven = salesRes.data['creditGiven'] ?? 0;
        _totalBills = salesRes.data['totalBills'] ?? 0;
        final List rawBills = salesRes.data['bills'] ?? [];
        _bills = rawBills.map((e) => BillModel.fromJson(e)).toList();
      }

      final profitRes = await _client.dio.get(ApiConstants.profit);
      if (profitRes.statusCode == 200 && profitRes.data['success'] == true) {
        _grossProfit = profitRes.data['grossProfit'] ?? 0;
      }

      final bestRes = await _client.dio.get(ApiConstants.bestSellers);
      if (bestRes.statusCode == 200 && bestRes.data['success'] == true) {
        final List raw = bestRes.data['bestSellers'] ?? [];
        _bestSellers = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(loc.t('tabMySales')),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(loc.t('salesOverview'), style: AppText.caption),
                              Text('$_totalBills ${loc.t('bills')}', style: AppText.label),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.formatPaise(_totalBilled),
                            style: AppText.amountLarge,
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${loc.t('grossProfit')}:', style: AppText.body),
                              Text(
                                CurrencyFormatter.formatPaise(_grossProfit),
                                style: AppText.amount.copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Breakdown
                    Text(loc.t('paymentBreakdown'), style: AppText.h3),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniCard(loc.t('cash'), _cashReceived, AppColors.primaryDark),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniCard(loc.t('upi'), _upiReceived, AppColors.success),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniCard(loc.t('credit'), _creditGiven, AppColors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Sales Trend Chart
                    SalesAnalyticsChart(bills: _bills),
                    const SizedBox(height: 20),

                    // Best Sellers
                    Text(loc.t('bestSellers'), style: AppText.h3),
                    const SizedBox(height: 12),

                    if (_bestSellers.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(loc.t('noSalesYet'), style: AppText.caption),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bestSellers.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final item = _bestSellers[idx];
                          final qty = item['totalQty'] ?? 0;
                          final revenue = item['revenue'] ?? 0;
                          final unit = item['unit'] ?? 'pcs';

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.mint,
                                child: Text('${idx + 1}', style: AppText.label),
                              ),
                              title: Text(item['name'] ?? '', style: AppText.label),
                              subtitle: Text(
                                '$qty $unit ${loc.t('unitsSold')}',
                                style: AppText.caption,
                              ),
                              trailing: Text(
                                CurrencyFormatter.formatPaise(revenue),
                                style: AppText.amount,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMiniCard(String title, int amountPaise, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.caption),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatPaise(amountPaise),
            style: AppText.amount.copyWith(color: color, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
