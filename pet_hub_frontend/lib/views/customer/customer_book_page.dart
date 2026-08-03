import 'package:flutter/material.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerBookPage extends StatelessWidget {
  final MerchantConfig config;
  final List<Map<String, dynamic>> activeServices;
  final String baseUrl;

  const CustomerBookPage({
    super.key,
    required this.config,
    this.activeServices = const [],
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.book,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month, color: config.primaryColor, size: 32),
                  const SizedBox(width: 12),
                  const Text("Book an Appointment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Reserve your appointment online in a few simple steps.", style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Preferred Service", border: OutlineInputBorder()),
                items: activeServices.map((s) {
                  return DropdownMenuItem<String>(
                    value: s['name'] ?? 'Service',
                    child: Text("${s['name']} - \$${((s['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2)}"),
                  );
                }).toList()..add(const DropdownMenuItem(value: 'Standard', child: Text("Standard Full Package"))),
                onChanged: (val) {},
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(labelText: "Your Full Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(labelText: "Contact Phone Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing booking request...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Confirm & Submit Booking"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}