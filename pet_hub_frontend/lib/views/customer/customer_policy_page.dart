import 'package:flutter/material.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerPolicyPage extends StatelessWidget {
  final MerchantConfig config;

  const CustomerPolicyPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.policy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Our Store Policies", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Please read our policies regarding appointments, cancellations, and service standards.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          _policyCard("1. Cancellations & Rescheduling", "We require at least 24 hours notice for any appointment cancellations or rescheduling requests. Cancellations made with short notice may forfeit their deposit."),
          _policyCard("2. Health & Safety Requirements", "For the safety of all pets and staff, pets must be up to date on required vaccinations prior to their scheduled visit."),
          _policyCard("3. Late Arrivals", "Arriving more than 15 minutes late may require rescheduling your appointment to ensure we give every customer full attention without delaying subsequent appointments."),
          _policyCard("4. Special Handling & Fees", "Special handling or extra care requirements will be assessed at arrival and may incur additional service charges."),
        ],
      ),
    );
  }

  Widget _policyCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Color(0xFF475569), height: 1.5)),
          ],
        ),
      ),
    );
  }
}