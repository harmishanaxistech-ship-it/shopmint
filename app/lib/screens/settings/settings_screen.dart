import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../auth/pin_login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLanguageDialog(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.t('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.t('cancel')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.t('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'K',
                      style: AppText.h2.copyWith(color: AppColors.onPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.shopName ?? loc.t('shopName'), style: AppText.bodyLarge),
                        const SizedBox(height: 2),
                        Text(user?.name ?? '', style: AppText.caption),
                        Text(user?.mobile ?? '', style: AppText.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      user?.role.toUpperCase() ?? 'OWNER',
                      style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options Card
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(loc.t('language')),
                  subtitle: Text(loc.getLanguageName(loc.currentLanguage)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(loc.t('receiptSettings')),
                  subtitle: Text(loc.t('receiptSettingsSubtitle')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(loc.t('helpSupport')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            icon: const Icon(Icons.logout),
            label: Text(loc.t('logout')),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.t('logoutConfirmTitle')),
                  content: Text(loc.t('logoutConfirmBody')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.t('no'))),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.t('yes'))),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const PinLoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
