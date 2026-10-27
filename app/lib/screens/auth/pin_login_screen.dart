import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_shell.dart';
import 'quick_register_screen.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _mobileController.text.trim(),
      _pinController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showLanguageSelector(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.t('selectLanguage'), style: AppText.h3),
              ),
              ListTile(
                title: const Text('English (Default)'),
                trailing: loc.currentLanguage == 'en' ? const Icon(Icons.check, color: AppColors.primaryDark) : null,
                onTap: () {
                  loc.setLocale('en');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('ગુજરાતી (Gujarati)'),
                trailing: loc.currentLanguage == 'gu' ? const Icon(Icons.check, color: AppColors.primaryDark) : null,
                onTap: () {
                  loc.setLocale('gu');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('हिन्दी (Hindi)'),
                trailing: loc.currentLanguage == 'hi' ? const Icon(Icons.check, color: AppColors.primaryDark) : null,
                onTap: () {
                  loc.setLocale('hi');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.language_outlined, size: 18),
            label: Text(loc.currentLanguage.toUpperCase()),
            onPressed: () => _showLanguageSelector(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: const Icon(Icons.lock_outline, size: 32, color: AppColors.onPrimary),
                ),
                const SizedBox(height: 24),
                Text(loc.t('loginTitle'), style: AppText.h1),
                const SizedBox(height: 8),
                Text(loc.t('loginSubtitle'), style: AppText.body),
                const SizedBox(height: 32),

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
                const SizedBox(height: 24),

                // Submit Button
                FilledButton(
                  onPressed: auth.isLoading ? null : _handleLogin,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(loc.t('loginButton')),
                ),
                const SizedBox(height: 20),

                // Go to register
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuickRegisterScreen()),
                    );
                  },
                  child: Text(loc.t('registerStorePrompt')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
