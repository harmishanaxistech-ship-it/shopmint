import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/locale_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../providers/auth_provider.dart';
import 'auth/pin_login_screen.dart';
import 'main_navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAuthed = await auth.checkAuthStatus();

    if (!mounted) return;
    if (isAuthed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PinLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.lgAll,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 44,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(loc.t('appName'), style: AppText.h1),
            const SizedBox(height: 8),
            Text(loc.t('appTagline'), style: AppText.caption),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
