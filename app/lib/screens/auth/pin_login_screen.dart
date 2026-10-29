import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
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
          content: Text(auth.errorMessage ?? 'Login failed. Please check credentials.'),
          backgroundColor: const Color(0xFFD94B4B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF17C3B2), Color(0xFF0F766E)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF084B45),
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.storefront_rounded, size: 38, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Shopkeeper Login',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Enter your registered mobile & 4-digit PIN',
                      style: TextStyle(fontSize: 13, color: Color(0xFF708784)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Mobile
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF153330)),
                    decoration: InputDecoration(
                      labelText: loc.t('mobileNumber'),
                      hintText: '10-digit mobile number',
                      prefixText: '+91 ',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                    ),
                    validator: (val) {
                      if (val == null || val.length != 10) {
                        return 'Please enter valid 10-digit mobile';
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF153330), letterSpacing: 4),
                    decoration: InputDecoration(
                      labelText: '4-Digit Security PIN',
                      hintText: '****',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                    ),
                    validator: (val) {
                      if (val == null || val.length != 4) {
                        return 'PIN must be exactly 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  Vanik3DButton(
                    variant: VanikButtonVariant.green,
                    height: 50,
                    fontSize: 15,
                    label: auth.isLoading ? 'Verifying...' : 'Login to Store',
                    icon: auth.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                    onPressed: auth.isLoading ? () {} : _handleLogin,
                  ),
                  const SizedBox(height: 12),

                  // Go to register
                  Vanik3DButton(
                    variant: VanikButtonVariant.beige,
                    height: 48,
                    fontSize: 14,
                    label: 'Register New Store',
                    icon: const Icon(Icons.add_business_outlined, size: 18, color: Color(0xFF0F766E)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuickRegisterScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Demo store bypass
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF708784)),
                      label: const Text(
                        'Continue to Demo Store',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        await auth.loginAsDemo();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
