import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
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
      role: 'owner',
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF153330),
        elevation: 0,
        title: const Text('Register Store', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Your Kirana Account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fast 30-second setup for your shop counter',
                  style: TextStyle(fontSize: 13, color: Color(0xFF708784)),
                ),
                const SizedBox(height: 24),

                // Shop Name
                TextFormField(
                  controller: _shopNameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF153330)),
                  decoration: InputDecoration(
                    labelText: 'Shop / Store Name',
                    hintText: 'e.g. Ramesh Kirana, Laxmi General Store',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Please enter your shop name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Owner Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF153330)),
                  decoration: InputDecoration(
                    labelText: 'Owner / Your Name',
                    hintText: 'e.g. Ramesh Patel',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EFED))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                    labelText: '4-Digit Login PIN',
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
                const SizedBox(height: 28),

                // Submit button
                Vanik3DButton(
                  variant: VanikButtonVariant.green,
                  height: 50,
                  fontSize: 15,
                  label: auth.isLoading ? 'Creating Store...' : 'Create & Open Store',
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                  onPressed: auth.isLoading ? () {} : _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
