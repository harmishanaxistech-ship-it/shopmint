import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/customer_provider.dart';

class AddCustomerModal extends StatefulWidget {
  const AddCustomerModal({super.key});

  @override
  State<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends State<AddCustomerModal> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.length < 2) return;

    final balanceRupees = double.tryParse(_openingBalanceController.text) ?? 0;
    final openingBalancePaise = CurrencyFormatter.toPaise(balanceRupees);

    setState(() => _isSaving = true);
    final custProv = Provider.of<CustomerProvider>(context, listen: false);
    final res = await custProv.createCustomer(
      name: name,
      mobile: _mobileController.text.trim(),
      openingBalance: openingBalancePaise,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res != null) {
      Navigator.pop(context, res);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res.name} added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

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
          Text(loc.t('addCustomer'), style: AppText.h3),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: '${loc.t('customer')} *',
              hintText: 'e.g. Suresh Kumar',
            ),
          ),
          const SizedBox(height: 12),

          // Mobile
          TextField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: loc.t('mobileNumber'),
              hintText: loc.t('mobileHint'),
              prefixText: '+91 ',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),

          // Opening balance
          TextField(
            controller: _openingBalanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: loc.t('openingBalance'),
              hintText: '0',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 20),

          // Button
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : Text(loc.t('save')),
          ),
        ],
      ),
    );
  }
}
