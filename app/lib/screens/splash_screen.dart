import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/pin_login_screen.dart';
import 'main_navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  final bool autoNavigate;
  const SplashScreen({super.key, this.autoNavigate = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isAuthed = await auth.checkAuthStatus();
      if (!mounted) return;

      if (isAuthed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        );
        return;
      }
    } catch (_) {}

    // Not authenticated: navigate to PinLoginScreen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PinLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF9),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF17C3B2), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF084B45),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'ShopMint',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F766E),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Never Run Out of Stock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF708784),
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
