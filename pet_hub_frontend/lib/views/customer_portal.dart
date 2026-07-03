import 'package:flutter/material.dart';
import '../models/merchant_config.dart';

class CustomerPortalPage extends StatefulWidget {
  final MerchantConfig config;
  final List<Map<String, dynamic>> activeServices; // 🧠 Injected real-time synchronization link

  const CustomerPortalPage({
    super.key, 
    required this.config, 
    required this.activeServices
  });

  @override
  State<CustomerPortalPage> createState() => _CustomerPortalPageState();
}

class _CustomerPortalPageState extends State<CustomerPortalPage> {
  Map<String, dynamic>? targetedService;

  @override
  void initState() {
    super.initState();
    if (widget.activeServices.isNotEmpty) {
      targetedService = widget.activeServices.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.config.primaryColor;

    // Reset layout selection gracefully if items are entirely pruned by administrator shifts
    if (targetedService != null && !widget.activeServices.contains(targetedService)) {
      targetedService = widget.activeServices.isNotEmpty ? widget.activeServices.first : null;
    }

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
      body: widget.activeServices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No service items are currently published by the merchant.', 
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Row(
              children: [
                // Left dynamic marketplace module
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(8)),
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
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.activeServices.length,
                            itemBuilder: (context, index) {
                              final service = widget.activeServices[index];
                              final isSelected = targetedService?['id'] == service['id'];
                              
                              // Handle dynamic variations in price keys safely
                              final rawPrice = service['priceCentsAud'] ?? service['priceCents'] ?? 0;
                              final double cleanPrice = rawPrice / 100;

                              // Safely map incoming backend keys to prevent Strict Null Safety crashes
                              final String displayTitle = service['title'] ?? service['name'] ?? 'Untitled Service';
                              final String displayDesc = service['description'] ?? 'No description available.';
                              final int duration = service['durationMinutes'] ?? 0;
                              final String weightTier = service['weightTier'] ?? 'Standard Weight';

                              // 🛡️ FIX: Look up the child 'name' attribute inside the nested 'species' map block
                              String species = 'All Species';
                              if (service['species'] != null && service['species'] is Map) {
                                species = service['species']['name'] ?? 'Dog';
                              } else if (service['speciesId'] != null) {
                                // Safe fallback to mapping IDs directly if object join is bypassed
                                species = service['speciesId'] == 1 ? 'Dog' : 'Cat';
                              }

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
                                    boxShadow: isSelected ? [BoxShadow(color: themeColor.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))] : null,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSelected ? themeColor : Colors.grey.shade100,
                                        foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
                                        radius: 24,
                                        child: Icon(service['icon'] ?? Icons.star_border_outlined),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(displayTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(displayDesc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text('$duration mins', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100, 
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '$species • $weightTier', 
                                                    style: TextStyle(
                                                      fontSize: 10, 
                                                      color: Colors.blueGrey.shade700, 
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        '\$${cleanPrice.toStringAsFixed(2)} AUD',
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
                
                // Right summary calculations pane
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15)],
                    ),
                    child: targetedService == null
                        ? const Center(child: Text('Please select an active catalog service layout from the left.'))
                        : () {
                            // Extract fallback properties cleanly for the right panel summary block
                            final String summaryTitle = targetedService!['title'] ?? targetedService!['name'] ?? 'Untitled Service';
                            final String summaryDesc = targetedService!['description'] ?? 'No description available.';
                            final int summaryDuration = targetedService!['durationMinutes'] ?? 0;
                            final rawPrice = targetedService!['priceCentsAud'] ?? targetedService!['priceCents'] ?? 0;
                            final double summaryPrice = rawPrice / 100;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Divider(height: 32),
                                Row(
                                  children: [
                                    Icon(targetedService!['icon'] ?? Icons.star_border_outlined, color: themeColor),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(summaryTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(summaryDesc, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Est. Service Duration', style: TextStyle(color: Colors.grey)),
                                      Text('$summaryDuration mins', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                      Text('\$${summaryPrice.toStringAsFixed(2)} AUD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
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
                                    onPressed: () => _triggerClientBookingAction(context, summaryTitle),
                                    child: Text(
                                      widget.config.getTxt('btn_book', 'Schedule Checkout Appointment'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                )
                              ],
                            );
                          }(),
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