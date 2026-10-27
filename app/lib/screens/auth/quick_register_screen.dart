import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_shell.dart';

class QuickRegisterScreen extends StatefulWidget {
  const QuickRegisterScreen({super.key});

  @override
  State<QuickRegisterScreen> createState() => _QuickRegisterScreenState();
}

class _QuickRegisterScreenState extends State<QuickRegisterScreen> {
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdmin = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      mobile: _mobileController.text.trim(),
      pin: _pinController.text.trim(),
      name: _nameController.text.trim(),
      shopName: _shopNameController.text.trim(),
      role: _isAdmin ? 'admin' : 'owner',
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.t('registerTitle')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(loc.t('registerSubtitle'), style: AppText.h2),
                const SizedBox(height: 24),

                // Mobile
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: loc.t('mobileNumber'),
                    hintText: loc.t('mobileHint'),
                    prefixText: '+91 ',
                    counterText: '',
                  ),
                  validator: (val) {
                    if (val == null || val.length != 10) {
                      return loc.t('mobileError');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4-digit PIN
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: loc.t('pin'),
                    hintText: loc.t('pinHint'),
                    counterText: '',
                  ),
                  validator: (val) {
                    if (val == null || val.length != 4) {
                      return loc.t('pinError');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Shopkeeper Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.t('ownerName'),
                    hintText: loc.t('ownerNameHint'),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return loc.t('ownerNameError');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Shop Name
                TextFormField(
                  controller: _shopNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.t('shopName'),
                    hintText: loc.t('shopNameHint'),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return loc.t('shopNameError');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Admin Role Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.t('adminRole'), style: AppText.label),
                          Text(loc.t('adminRoleSubtitle'), style: AppText.caption),
                        ],
                      ),
                      Switch(
                        value: _isAdmin,
                        onChanged: (val) => setState(() => _isAdmin = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit button
                FilledButton(
                  onPressed: auth.isLoading ? null : _handleRegister,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(loc.t('createStoreButton')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
