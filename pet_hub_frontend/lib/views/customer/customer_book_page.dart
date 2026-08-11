import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/merchant_config.dart';
import 'customer_layout.dart';
import '../booking_form_page.dart';

class CustomerBookPage extends StatefulWidget {
  final MerchantConfig config;
  final String baseUrl;
  final String? authToken; // Optional here depending on if customer portal requires token auth
  final String merchantId; // Optional merchantId for API calls

  const CustomerBookPage({
    super.key,
    required this.config,
    required this.baseUrl,
    this.authToken,
    required this.merchantId,
  });
  
  @override
  State<CustomerBookPage> createState() => _CustomerBookPageState();
}

class _CustomerBookPageState extends State<CustomerBookPage> {
  List<Map<String, dynamic>> liveServiceMatrices = [];
  bool _isServiceLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchServiceMatrices();
  }

  Future<void> _fetchServiceMatrices() async {
    // 1. Guard against empty or null merchant ID configurations right away
    if (widget.merchantId == null || widget.merchantId!.trim().isEmpty) {
      _showSnackBar('❌ Application configuration missing valid Merchant ID.');
      return;
    }

    setState(() => _isServiceLoading = true);
    try {
      // 2. Ensure base URL path doesn't accidentally form malformed queries if strings aren't sanitised 
      final String requestUrl = '${widget.baseUrl}/api/v1/matrix?merchantId=${widget.merchantId}';
      
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          if (widget.authToken != null) 'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            liveServiceMatrices = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        // Fallback context handling for 400 bad requests from backend query blocks
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to fetch options matrix.';
        _showSnackBar('❌ $errorMessage');
      }
    } catch (_) {
      _showSnackBar('❌ Transport layer connection fault.');
    } finally {
      if (mounted) setState(() => _isServiceLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.config.primaryColor;

    // Filter only active records from the payload
    final displayedServices = liveServiceMatrices
        .where((service) => service['isActive'] ?? true)
        .toList();

    // Group by unique service names to avoid duplicates in the main menu list
    final uniqueServiceNames = displayedServices
        .map((s) => (s['name'] ?? s['title'] ?? 'Untitled Service').toString().trim())
        .toSet()
        .toList();

    return CustomerLayoutWrapper(
      config: widget.config,
      activeTab: CustomerTab.book,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.withAlpha(40),
                  themeColor.withAlpha(15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor.withAlpha(60)),
            ),
            child: Text(
              "We kindly recommend that you review our service details and confirm your dog's coat condition before making a booking. Please note that if an incorrect size or coat condition is selected at the time of booking due to your dog's weight or coat condition, we will proceed with the billing based on the actual size and coat condition of your pet and dog grooming times vary based on factors like behavior, size, and coat condition. We'll provide an estimate when you're in-store. Thank you for understanding!",
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Available Service Catalog Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          if (_isServiceLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
            )
          else if (uniqueServiceNames.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No treatment offerings are currently published.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: uniqueServiceNames.length,
              itemBuilder: (context, index) {
                final serviceName = uniqueServiceNames[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: () {
                        final variants = displayedServices.where((element) {
                          final name = (element['name'] ?? element['title'] ?? '').toString().trim();
                          return name == serviceName;
                        }).toList();

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
                                baseUrl: widget.baseUrl,
                                merchantId: widget.merchantId, // Pass the merchantId to the booking form
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
        ],
      ),
    );
  }
}