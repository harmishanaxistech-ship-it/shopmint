import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiClient _client = ApiClient();
  bool _isLoading = true;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final statsRes = await _client.dio.get(ApiConstants.adminStats);
      if (statsRes.statusCode == 200 && statsRes.data['success'] == true) {
        _stats = statsRes.data['stats'] ?? {};
      }

      final shopsRes = await _client.dio.get(ApiConstants.adminShops);
      if (shopsRes.statusCode == 200 && shopsRes.data['success'] == true) {
        final List raw = shopsRes.data['shops'] ?? [];
        _shops = raw.map((e) => Map<String, dynamic>.from(e)).toList();
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
        title: Text(loc.t('adminPanel')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(loc.t('platformStats'), style: AppText.h3),
                    const SizedBox(height: 12),

                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatBox(loc.t('totalStores'), '${_stats['totalShops'] ?? 0}'),
                        _buildStatBox(loc.t('totalUsers'), '${_stats['totalUsers'] ?? 0}'),
                        _buildStatBox(loc.t('totalBillsCount'), '${_stats['totalBills'] ?? 0}'),
                        _buildStatBox(
                          loc.t('totalVolume'),
                          CurrencyFormatter.formatPaise(_stats['totalVolume'] ?? 0, hideZeroDecimals: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(loc.t('allStores'), style: AppText.h3),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _shops.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final s = _shops[idx];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s['name'] ?? '', style: AppText.bodyLarge),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        borderRadius: AppRadius.smAll,
                                      ),
                                      child: Text(s['type'] ?? 'Kirana', style: AppText.caption),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${loc.t('owner')}: ${s['ownerName'] ?? ''} • ${loc.t('phone')}: ${s['mobile'] ?? ''}',
                                  style: AppText.caption,
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${loc.t('productsCount')}: ${s['productCount'] ?? 0}', style: AppText.caption),
                                    Text('${loc.t('billsCount')}: ${s['billCount'] ?? 0}', style: AppText.caption),
                                  ],
                                ),
                              ],
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

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 4),
          Text(value, style: AppText.h3.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}
