import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  late CustomerModel _customer;
  List<LedgerEntryModel> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final custProv = Provider.of<CustomerProvider>(context, listen: false);
    final entries = await custProv.fetchLedger(_customer.id);
    if (!mounted) return;

    final updated = custProv.customers.firstWhere(
      (c) => c.id == _customer.id,
      orElse: () => _customer,
    );

    setState(() {
      _customer = updated;
      _entries = entries;
      _isLoading = false;
    });
  }

  void _showPaymentModal(LocaleProvider loc) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String mode = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(loc.t('receivePayment'), style: AppText.h3),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: '${loc.t('paymentAmount')} *', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Cash', 'UPI', 'Other'].map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(m),
                          selected: mode == m,
                          onSelected: (_) => setModalState(() => mode = m),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(labelText: loc.t('noteOptional')),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      final rupees = double.tryParse(amountCtrl.text) ?? 0;
                      if (rupees > 0) {
                        final custProv = Provider.of<CustomerProvider>(context, listen: false);
                        await custProv.receivePayment(
                          _customer.id,
                          CurrencyFormatter.toPaise(rupees),
                          mode: mode,
                          note: noteCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadLedger();
                      }
                    },
                    child: Text(loc.t('receivePayment')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreditModal(LocaleProvider loc) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.t('addCredit'), style: AppText.h3),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '${loc.t('creditAmount')} *', prefixText: '₹ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(labelText: loc.t('note')),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final rupees = double.tryParse(amountCtrl.text) ?? 0;
                  if (rupees > 0) {
                    final custProv = Provider.of<CustomerProvider>(context, listen: false);
                    await custProv.addCredit(
                      _customer.id,
                      CurrencyFormatter.toPaise(rupees),
                      note: noteCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadLedger();
                  }
                },
                child: Text(loc.t('addCredit')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy, hh:mm a');
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_customer.name),
      ),
      body: Column(
        children: [
          // Top Balance Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.t('pendingUdhaar'), style: AppText.body),
                    Text(
                      CurrencyFormatter.formatPaise(_customer.balance),
                      style: AppText.amountLarge.copyWith(
                        color: _customer.balance > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (_customer.mobile.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(_customer.mobile, style: AppText.caption),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // 2 Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: Text(loc.t('receivePayment')),
                        onPressed: () => _showPaymentModal(loc),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: Text(loc.t('addCredit')),
                        onPressed: () => _showCreditModal(loc),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ledger Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(loc.t('ledgerTimeline'), style: AppText.label),
            ),
          ),
          const SizedBox(height: 8),

          // Entries List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.teal,
              backgroundColor: Colors.white,
              onRefresh: _loadLedger,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(child: Text(loc.t('noTransactions'), style: AppText.caption)),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _entries.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                          final e = _entries[idx];
                          final isCredit = e.isCredit;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCredit ? AppColors.errorSoft : AppColors.successSoft,
                                child: Icon(
                                  isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isCredit ? AppColors.error : AppColors.success,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                isCredit ? loc.t('creditGiven') : loc.t('paymentReceived'),
                                style: AppText.label.copyWith(
                                  color: isCredit ? AppColors.error : AppColors.success,
                                ),
                              ),
                              subtitle: Text(
                                '${dateFormat.format(e.createdAt)}${e.note.isNotEmpty ? '\n${e.note}' : ''}',
                                style: AppText.caption,
                              ),
                              isThreeLine: e.note.isNotEmpty,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? '+' : '-'}${CurrencyFormatter.formatPaise(e.amount)}',
                                    style: AppText.amount.copyWith(
                                      color: isCredit ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    '${loc.t('balanceAfter')}: ${CurrencyFormatter.formatPaise(e.balanceAfter)}',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
