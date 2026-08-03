import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerServicesPage extends StatelessWidget {
  final MerchantConfig config;
  final List<Map<String, dynamic>> activeServices;

  const CustomerServicesPage({
    super.key,
    required this.config,
    this.activeServices = const [],
  });

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.service,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Our Services", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Choose from our comprehensive selection of professional grooming packages.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          if (activeServices.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text("No services currently listed. Please check back soon!"),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeServices.length,
              itemBuilder: (context, index) {
                final service = activeServices[index];
                final price = ((service['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2);
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: config.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.content_cut, color: config.primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service['name'] ?? 'General Service', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Coat Type: ${service['coatType'] ?? 'All'} • Weight Tier: ${service['weightTier'] ?? 'Standard'}"),
                              Text("Duration: ${service['durationMinutes'] ?? 60} minutes", style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("\$$price AUD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: config.primaryColor)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => context.go('/customer/book'),
                              style: ElevatedButton.styleFrom(backgroundColor: config.primaryColor, foregroundColor: Colors.white),
                              child: const Text("Select"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}