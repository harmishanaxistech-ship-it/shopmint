import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  final ApiClient _client = ApiClient();

  int _totalBilled = 1845000; // in paise (₹18,450)
  int _cashReceived = 825000;
  int _upiReceived = 760000;
  int _creditGiven = 260000;
  int _totalBills = 46;
  int _grossProfit = 294000;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final salesRes = await _client.dio.get(ApiConstants.sales);
      if (salesRes.statusCode == 200 && salesRes.data['success'] == true) {
        setState(() {
          _totalBilled = salesRes.data['totalBilled'] ?? _totalBilled;
          _cashReceived = salesRes.data['cashReceived'] ?? _cashReceived;
          _upiReceived = salesRes.data['upiReceived'] ?? _upiReceived;
          _creditGiven = salesRes.data['creditGiven'] ?? _creditGiven;
          _totalBills = salesRes.data['totalBills'] ?? _totalBills;
        });
      }
      final profitRes = await _client.dio.get(ApiConstants.profit);
      if (profitRes.statusCode == 200 && profitRes.data['success'] == true) {
        setState(() {
          _grossProfit = profitRes.data['grossProfit'] ?? _grossProfit;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final double revenueRupees = _totalBilled / 100.0;
    final double profitRupees = _grossProfit / 100.0;
    final double avgBillRupees = _totalBills > 0 ? (revenueRupees / _totalBills) : 401;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReports,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
            children: [
              // Header
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Sales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, color: AppColors.muted, size: 19),
                  SizedBox(width: 7),
                  Text(
                    'Today',
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 17),

              // Today's Revenue Teal Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TODAY'S REVENUE",
                      style: TextStyle(
                        color: Color(0xFFCCFBF1),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${revenueRupees.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Color(0xFF99F6E4), size: 17),
                        const SizedBox(width: 4),
                        const Text(
                          '12.8% vs yesterday',
                          style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          'Gross profit  ₹${profitRupees.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Metrics Row: Bills & Avg. Bill
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'BILLS',
                      value: '$_totalBills',
                      icon: Icons.receipt_long,
                      tint: AppColors.paleMint,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MetricCard(
                      title: 'AVG. BILL',
                      value: '₹${avgBillRupees.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      tint: const Color(0xFFFFF3D6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Payment Breakdown
              const Text(
                'Payment breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PayMetric(
                      label: 'Cash',
                      value: '₹${(_cashReceived / 100).toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayMetric(
                      label: 'UPI',
                      value: '₹${(_upiReceived / 100).toStringAsFixed(0)}',
                      icon: Icons.qr_code_2,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayMetric(
                      label: 'Credit',
                      value: '₹${(_creditGiven / 100).toStringAsFixed(0)}',
                      icon: Icons.menu_book_outlined,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sales Trend
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sales trend',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    'This week  ▾',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 190,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const SalesAnalyticsChart(),
              ),
              const SizedBox(height: 20),

              // Best Sellers
              const Text(
                'Best sellers',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              ...[
                (
                  'Amul Gold Milk',
                  '82 sold',
                  '₹2,788',
                  Icons.water_drop_outlined,
                  const Color(0xFFE8F5FF),
                ),
                (
                  'Tata Salt',
                  '64 sold',
                  '₹1,792',
                  Icons.grain,
                  const Color(0xFFE8F6F5),
                ),
                (
                  'Aashirvaad Atta',
                  '21 sold',
                  '₹6,069',
                  Icons.breakfast_dining,
                  const Color(0xFFFFF1DC),
                ),
              ].asMap().entries.map((entry) {
                final e = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFDDF0ED))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.bg,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: e.$5,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.$4, color: AppColors.teal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.$1,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              e.$2,
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        e.$3,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String title, value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: AppColors.teal),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, letterSpacing: .7, color: AppColors.muted),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _PayMetric extends StatelessWidget {
  const _PayMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      );
}

class SalesAnalyticsChart extends StatelessWidget {
  const SalesAnalyticsChart({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ChartPainter(),
        child: const SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('M', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                Text('T', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                Text('W', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                Text('T', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                Text('F', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                Text('S', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                Text('S', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      );
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [0.42, 0.7, 0.54, 0.83, 0.62, 0.95, 0.48];
    final chartHeight = size.height - 22;
    const gap = 12.0;
    final barWidth = (size.width - 7 * gap) / 7;
    final grid = Paint()
      ..color = const Color(0xFFE8F3F1)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 0; i < values.length; i++) {
      final x = gap / 2 + i * (barWidth + gap);
      final h = chartHeight * values[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - h, barWidth, h),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = i == 5 ? AppColors.mint : const Color(0xFFB9EAE3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
