import 'package:flutter/material.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerCareerPage extends StatelessWidget {
  final MerchantConfig config;

  const CustomerCareerPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.career,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Join Our Team", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Explore open career opportunities and grow with us.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          _jobCard(
            title: "Senior Specialist",
            type: "Full-Time",
            description: "Looking for an experienced professional with 2+ years of relevant industry experience.",
          ),
          _jobCard(
            title: "Assistant / Service Associate",
            type: "Part-Time",
            description: "Entry-level position. Experience preferred but training is provided for motivated candidates.",
          ),
        ],
      ),
    );
  }

  Widget _jobCard({
    required String title,
    required String type,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(type, style: TextStyle(color: config.primaryColor, fontWeight: FontWeight.bold)),
                  backgroundColor: config.primaryColor.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: config.primaryColor, foregroundColor: Colors.white),
              child: const Text("Apply Now"),
            )
          ],
        ),
      ),
    );
  }
}