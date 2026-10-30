import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                  'ShopMint Privacy Policy',
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
                  '1. Information We Collect',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'ShopMint collects store details, product inventory catalogs, sales receipts, customer contact information for Udhaar ledgers, and transaction records needed to provide retail billing services.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF527270)),
                ),
                SizedBox(height: 14),
                Text(
                  '2. How We Use Information',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'Your store data is used exclusively to generate bills, calculate sales analytics, maintain customer ledgers, and synchronize your inventory across devices.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF527270)),
                ),
                SizedBox(height: 14),
                Text(
                  '3. Data Protection and Storage',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'All sensitive authentication tokens and customer information are stored securely using device level encrypted storage and authenticated cloud synchronization. We do not sell or share store data with third party advertisers.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF527270)),
                ),
                SizedBox(height: 14),
                Text(
                  '4. Contact Us',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F2A29)),
                ),
                SizedBox(height: 6),
                Text(
                  'If you have questions regarding this Privacy Policy or your store data, contact support at support@shopmint.local.',
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

