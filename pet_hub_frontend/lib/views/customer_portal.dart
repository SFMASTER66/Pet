import 'package:flutter/material.dart';
import '../models/merchant_config.dart';

class CustomerPortalPage extends StatefulWidget {
  final MerchantConfig config;
  const CustomerPortalPage({super.key, required this.config});

  @override
  State<CustomerPortalPage> createState() => _CustomerPortalPageState();
}

class _CustomerPortalPageState extends State<CustomerPortalPage> {
  final List<Map<String, dynamic>> premiumServices = [
    {
      'title': 'Signature Full Style Grooming',
      'description': 'Includes specialized bath, complete clipping style, hair treatment, nail file, and ear irrigation care.',
      'duration': '90 mins',
      'price': 120.0,
      'icon': Icons.cut_outlined
    },
    {
      'title': 'Ultrasonic Deep Teeth Cleaning',
      'description': 'Advanced calculus removal safely without general sedation techniques. Refreshes oral breath cycles.',
      'duration': '30 mins',
      'price': 50.0,
      'icon': Icons.clean_hands_outlined
    },
    {
      'title': 'Hydrotherapy Mineral Treatment Bath',
      'description': 'Soothing warm water skin bubble treatment infused with natural essential oil remedies.',
      'duration': '45 mins',
      'price': 65.0,
      'icon': Icons.waves
    }
  ];

  Map<String, dynamic>? targetedService;

  @override
  void initState() {
    super.initState();
    targetedService = premiumServices.first;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.config.primaryColor;

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
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'Client Mode Portal',
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // Left Marketplace Services Selection Panel
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant Promotional Headline Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [themeColor, themeColor.withValues(alpha: 0.8)]),
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
                          'Experience premium smart treatment plans for your beloved animal companion assets today.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.config.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Available Treatment Offerings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const SizedBox(height: 16),
                  
                  // Interactive Services Grid Listing Map
                  Expanded(
                    child: ListView.builder(
                      itemCount: premiumServices.length,
                      itemBuilder: (context, index) {
                        final service = premiumServices[index];
                        final isSelected = targetedService?['title'] == service['title'];

                        return GestureDetector(
                          onTap: () => setState(() => targetedService = service),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? themeColor : Colors.grey.shade200, width: 2),
                              boxShadow: isSelected ? [BoxShadow(color: themeColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isSelected ? themeColor : Colors.grey.shade100,
                                  foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
                                  radius: 24,
                                  child: Icon(service['icon']),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(service['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(service['description'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(service['duration'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  '\$${service['price']} AUD',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Right Order Summary Details Panel
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
              ),
              child: targetedService == null
                  ? const Center(child: Text('Please select an active catalog service layout from the left.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Icon(targetedService!['icon'], color: themeColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text(targetedService!['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(targetedService!['description'], style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Est. Service Duration', style: TextStyle(color: Colors.grey)),
                              Text(targetedService!['duration'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total Payable Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$${targetedService!['price']} AUD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _triggerClientBookingAction(context, targetedService!['title']),
                            child: Text(
                              widget.config.getTxt('btn_book', 'Schedule Checkout Appointment'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        )
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  void _triggerClientBookingAction(BuildContext context, String currentServiceTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Reservation Intent Triggered'),
          ],
        ),
        content: Text('Successfully sent customer request routing to database for: "$currentServiceTitle". Waiting for store merchant approval processes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Acknowledged'),
          )
        ],
      ),
    );
  }
}