import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCDE9E5)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ShopMint Terms of Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F766E),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Last updated: October 2026',
                  style: TextStyle(fontSize: 12, color: Color(0xFF527270)),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'By registering, installing, or using the ShopMint retail application, store owners agree to be bound by these Terms and Conditions.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF527270)),
                ),
                SizedBox(height: 14),
                Text(
                  '2. Retail Operations and Accuracy',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'Store owners are responsible for maintaining accurate product selling prices, purchase costs, inventory counts, and customer credit ledger balances.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF527270)),
                ),
                SizedBox(height: 14),
                Text(
                  '3. Account Security',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'Store cashiers and owners must safeguard their four digit security PIN. Any actions performed under an authenticated store session remain the responsibility of the account holder.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF527270)),
                ),
                SizedBox(height: 14),
                Text(
                  '4. Service Availability',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'ShopMint provides offline first billing capabilities with cloud database synchronization when connectivity is present. Periodic backups and network integrity are maintained in accordance with standard operational practices.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF527270)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

