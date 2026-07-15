import 'package:flutter/material.dart';
import '../models/merchant_config.dart';
import 'booking_form_page.dart'; // Import your new booking form page

class CustomerPortalPage extends StatefulWidget {
  final MerchantConfig config;
  final List<Map<String, dynamic>> activeServices; // Acts as your ServicePricingMatrix records
  final String baseUrl; // Added to receive the dynamic URL

  const CustomerPortalPage({
    super.key, 
    required this.config, 
    required this.activeServices,
    required this.baseUrl, // Required in constructor
  });

  @override
  State<CustomerPortalPage> createState() => _CustomerPortalPageState();
}

class _CustomerPortalPageState extends State<CustomerPortalPage> {
  @override
  Widget build(BuildContext context) {
    final themeColor = widget.config.primaryColor;

    // Filter only active records from the database table payload
    final displayedServices = widget.activeServices.where((service) => service['isActive'] ?? true).toList();

    // Grouping by unique service names to avoid duplicates in the menu
    final uniqueServiceNames = displayedServices
        .map((s) => (s['name'] ?? s['title'] ?? 'Untitled Service').toString().trim())
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Row(
          children: [
            Text(widget.config.logoIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              widget.config.businessName,
              style: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: themeColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'Client Mode Portal',
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: uniqueServiceNames.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No treatment offerings are currently published.', 
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant Welcome Header Area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [themeColor, themeColor.withAlpha(200)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to ${widget.config.businessName} ${widget.config.logoIcon}',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select an available service menu below to calculate customized pricing and book a treatment calendar appointment.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Available Service Catalog Menu', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)
                  ),
                  const SizedBox(height: 16),
                  
                  // Main catalog table showing only service names
                  Expanded(
                    child: ListView.builder(
                      itemCount: uniqueServiceNames.length,
                      itemBuilder: (context, index) {
                        final serviceName = uniqueServiceNames[index];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: themeColor.withAlpha(20),
                              foregroundColor: themeColor,
                              child: const Icon(Icons.content_paste_search_outlined),
                            ),
                            title: Text(
                              serviceName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                // Filter variations matching this specific service name matrix selection
                                final variants = displayedServices.where((element) {
                                  final name = (element['name'] ?? element['title'] ?? '').toString().trim();
                                  return name == serviceName;
                                }).toList();

                                // Show a compact desktop-friendly pop-up dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    clipBehavior: Clip.antiAlias,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 550, maxHeight: 850),
                                      child: BookingFormPage(
                                        serviceName: serviceName,
                                        variantsMatrix: variants,
                                        themeColor: themeColor,
                                        config: widget.config,
                                        baseUrl: widget.baseUrl, // Injected the URL dynamically here
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Book Plan'),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }
}