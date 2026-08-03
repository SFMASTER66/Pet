import 'package:flutter/material.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerContactPage extends StatelessWidget {
  final MerchantConfig config;

  const CustomerContactPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.contact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Get In Touch", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Have questions or need assistance? We are here to help.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: config.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.business, color: config.primaryColor),
                    ),
                    title: const Text("Business Name"),
                    subtitle: Text(config.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.email, color: Colors.blue),
                    ),
                    title: const Text("Email Support"),
                    subtitle: const Text("support@workspace.com"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: const Icon(Icons.phone, color: Colors.green),
                    ),
                    title: const Text("Phone Number"),
                    subtitle: const Text("+61 (02) 8000 0000"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.location_on, color: Colors.orange),
                    ),
                    title: const Text("Store Location"),
                    subtitle: const Text("123 Business Way, Sydney NSW 2000"),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}