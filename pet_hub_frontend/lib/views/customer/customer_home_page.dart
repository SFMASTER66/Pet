import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerHomePage extends StatelessWidget {
  final MerchantConfig config;
  final String baseUrl;

  const CustomerHomePage({
    super.key,
    required this.config,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(config.logoIcon, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  "Welcome to ${config.businessName}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Providing top-tier pet care and specialized services tailored for your needs.",
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/customer/book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Book Appointment Now'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/customer/service'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: const Text('View All Services'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}