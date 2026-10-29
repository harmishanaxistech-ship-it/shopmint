import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/customer_model.dart';
import '../../models/shop_mint_models.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/shop_mint_components.dart';

class MySalesTab extends StatefulWidget {
  const MySalesTab({
    super.key,
    required this.orders,
    required this.products,
    required this.onOrdersChanged,
    this.storeName = 'Ramesh Kirana',
  });

  final List<OrderRecord> orders;
  final List<ProductItem> products;
  final VoidCallback onOrdersChanged;
  final String storeName;

  @override
  State<MySalesTab> createState() => _MySalesTabState();
}

class _MySalesTabState extends State<MySalesTab> {
  int _view = 0; // 0: Analytics, 1: Best Items
  bool _ordersExpanded = true;
  final Set<int> _expandedOrderIndices = {0};

  @override
  Widget build(BuildContext context) {
    final todaySales = widget.orders.fold<double>(0, (s, o) => s + o.total);
    final todayProfit = widget.orders.fold<double>(0, (s, o) => s + o.profit);

    return Column(
      children: [
        _SalesTopBar(storeName: widget.storeName),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: segmentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentTab(
                    label: 'Analytics',
                    selected: _view == 0,
                    onTap: () => setState(() => _view = 0),
                  ),
                ),
                Expanded(
                  child: SegmentTab(
                    label: 'Best Items',
                    selected: _view == 1,
                    onTap: () => setState(() => _view = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _view == 0
              ? _buildAnalyticsView(todaySales, todayProfit)
              : _buildBestItemsView(),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView(double todaySales, double todayProfit) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          // Sales of Day + 7 Day Bar Chart card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line),
              boxShadow: const [
                BoxShadow(color: Color(0x060F766E), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sales of day', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${todaySales.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Profit: ₹${todayProfit.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: teal),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: mintTint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: line),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Month', style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w600)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'September 26',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal),
                              ),
                              Icon(Icons.arrow_drop_down, size: 16, color: teal),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 7-day Bar chart with Teal gradient Today bar
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const ChartBar(date: '22 Sep', amount: 0, heightFraction: 0.05, isToday: false),
                      const ChartBar(date: '23 Sep', amount: 0, heightFraction: 0.05, isToday: false),
                      const ChartBar(date: '24 Sep', amount: 0, heightFraction: 0.05, isToday: false),
                      const ChartBar(date: '25 Sep', amount: 890, heightFraction: 0.60, isToday: false),
                      const ChartBar(date: '26 Sep', amount: 330, heightFraction: 0.35, isToday: false),
                      ChartBar(date: 'Today', amount: todaySales.toInt(), heightFraction: 0.90, isToday: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Collapsible Orders on the day
          InkWell(
            onTap: () => setState(() => _ordersExpanded = !_ordersExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Orders on the day',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _ordersExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: ink,
                  ),
                ],
              ),
            ),
          ),
          if (_ordersExpanded) ...[
            const SizedBox(height: 6),
            ...List.generate(widget.orders.length, (i) {
              final order = widget.orders[i];
              final isExpanded = _expandedOrderIndices.contains(i);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line),
                  boxShadow: const [
                    BoxShadow(color: Color(0x060F766E), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedOrderIndices.remove(i);
                          } else {
                            _expandedOrderIndices.add(i);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              order.time,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.remove_red_eye_outlined, size: 16, color: teal),
                            if (order.isUdhaar) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: order.isPaid ? mintTint : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: order.isPaid ? mint : const Color(0xFFFCA5A5)),
                                ),
                                child: Text(
                                  order.isPaid ? 'Paid' : 'Udhaar: ${order.customerName ?? "Customer"}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: order.isPaid ? teal : red,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '${order.items.length} Items',
                              style: const TextStyle(fontSize: 12, color: muted),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '₹${order.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded) ...[
                      const Divider(height: 1, color: line),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.isUdhaar) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Udhaar: ',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: red),
                                      ),
                                      Text(
                                        order.customerName != null && order.customerName!.isNotEmpty
                                            ? '${order.customerName} (${order.customerPhone ?? ""})'
                                            : (order.customerPhone ?? 'Customer'),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                                      ),
                                    ],
                                  ),
                                  if (order.isPaid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: mintTint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal)),
                                    ),
                                ],
                              ),
                              if (!order.isPaid) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Vanik3DButton(
                                        variant: VanikButtonVariant.beige,
                                        height: 38,
                                        fontSize: 12,
                                        icon: const Icon(Icons.chat_bubble_rounded, size: 14, color: teal),
                                        label: 'Message',
                                        onPressed: () => _showWhatsAppReminderDialog(context, order),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Vanik3DButton(
                                        variant: VanikButtonVariant.green,
                                        height: 38,
                                        fontSize: 12,
                                        icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                                        label: 'Paid',
                                        onPressed: () {
                                          setState(() => order.isPaid = true);
                                          widget.onOrdersChanged();
                                          showNote(context, 'Udhaar marked as paid!');
                                          try {
                                            final custProv = Provider.of<CustomerProvider>(context, listen: false);
                                            final match = custProv.customers.firstWhere(
                                              (c) => c.name.toLowerCase() == (order.customerName ?? '').toLowerCase() || (order.customerPhone != null && c.mobile == order.customerPhone),
                                              orElse: () => CustomerModel(id: '', name: '', mobile: '', balance: 0),
                                            );
                                            if (match.id.isNotEmpty) {
                                              custProv.receivePayment(
                                                match.id,
                                                (order.total * 100).toInt(),
                                                mode: 'Cash',
                                                note: 'Bill settled',
                                              );
                                            }
                                          } catch (_) {}
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '₹${order.total.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(width: 1, height: 14, color: line),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Profit: ₹${order.profit.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: green),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: canvas,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: line),
                                  ),
                                  child: Text(
                                    order.time,
                                    style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...order.items.map(
                              (it) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    ProductThumbnail(name: it.product.name, size: 28, imageUrl: it.product.imageUrl),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        it.product.name,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
                                      ),
                                    ),
                                    Text(
                                      '${it.qty}pc',
                                      style: const TextStyle(fontSize: 12, color: muted),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '₹${it.total.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      );

  Widget _buildBestItemsView() {
    final sorted = List<ProductItem>.from(widget.products)
      ..sort((a, b) => b.soldCount.compareTo(a.soldCount));

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: sorted.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = sorted[index];
            final revenue = item.soldCount * item.price;
            final itemProfit = item.soldCount * item.profit;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
                boxShadow: const [
                  BoxShadow(color: Color(0x060F766E), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  ProductThumbnail(name: item.name, size: 48, imageUrl: item.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${revenue.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹${itemProfit.toStringAsFixed(1)} profit',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teal),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Sold ${item.soldCount}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: teal, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x20000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.insights_rounded, color: teal, size: 28),
          ),
        ),
      ],
    );
  }
}

class _SalesTopBar extends StatelessWidget {
  const _SalesTopBar({required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: mintTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CustomPaint(painter: ShopkeeperAvatarPainter()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(18, 18),
                      painter: ShopMintBrandLogoPainter(),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ShopMint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

void _showWhatsAppReminderDialog(BuildContext context, OrderRecord order) {
  final itemsText = order.items.map((i) => '• ${i.product.name} (${i.qty}.0 pc)').join('\n');
  final reminder = 'Hello, this is a gentle reminder about your pending udhaar of ₹${order.total.toStringAsFixed(1)} for your purchase at Ramesh Kirana.\n\nHere are the items:\n$itemsText\n\nPlease clear it at your earliest convenience.\n\nManaged via ShopMint';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('WhatsApp Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF075E54),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          reminder,
          style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: muted)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: reminder));
            Navigator.pop(ctx);
            showNote(context, 'WhatsApp message copied to clipboard!');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy and Open'),
        ),
      ],
    ),
  );
}

