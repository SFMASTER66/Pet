import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerHomePage extends StatefulWidget {
  final MerchantConfig config;
  final String baseUrl;

  const CustomerHomePage({
    super.key,
    required this.config,
    required this.baseUrl,
  });

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  final List<String> imagePaths = List.generate(
    35,
    (index) => 'assets/images/folder/${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_scrollController.hasClients) return;
      
      final maxExtent = _scrollController.position.maxScrollExtent;
      final currentExtent = _scrollController.offset;
      const scrollAmount = 450.0;

      if (currentExtent >= maxExtent - 10) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.animateTo(
          currentExtent + scrollAmount,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _manualScroll(double offset) {
    _autoScrollTimer?.cancel();
    _scrollController.animateTo(
      _scrollController.offset + offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return CustomerLayoutWrapper(
      config: widget.config,
      activeTab: CustomerTab.home,
      child: Column(
        children: [
          // ================= 1. NO WHITE GAP HERO IMAGE =================
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Full Bleed Image Edge-To-Edge
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/folder/home_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: const Color(0xFFFAF6EE));
                    },
                  ),
                ),

                // Lighter text overlay card
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 48,
                    vertical: isMobile ? 30 : 60,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 760,
                      ),
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6EE).withOpacity(0.70),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Grooming Price Adjustment Notice",
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 34,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A5D4E),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Dear Amazing Clients,",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                color: Colors.black87,
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(
                                  text: "We would like to inform you that, starting ",
                                ),
                                WidgetSpan(
                                  child: Container(
                                    color: const Color(0xFFE2E874),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: const Text(
                                      "Sep 1st, 2026",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ", there will be a slight adjustment to some of our dog grooming service pricing. This update comes in response to rising costs of grooming products and materials. Please rest assured, this change is essential to help us maintain the high standards of care and service that your pets deserve.",
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFE2E874),
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            child: Text(
                              "The updated price list will be available in July",
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "We truly appreciate your understanding and continued support. Thank you for trusting us with the care of your beloved pets—we look forward to continuing to serve you with love and excellence.",
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= 2. POLICY NOTICE (Standard Margins Kept) =================
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 48,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Important Notice for All Clients",
                        style: TextStyle(
                          fontSize: isMobile ? 26 : 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A5D4E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Welcome to ${widget.config.businessName}. Your pet's safety, health and comfort come first. To ensure the best care for every guest, please note our grooming policies:",
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    _buildPolicyBullet(
                      title: "Vaccinations and annual checkups",
                      description:
                          "All new clients must present proof of current vaccinations at the first visit. Dogs should receive an annual veterinary health check and up-to-date vaccinations.",
                    ),
                    _buildPolicyBullet(
                      title: "Known serious medical conditions",
                      description:
                          "Please inform us of any diagnosed serious conditions (e.g., heart disease, epilepsy, cancer) and provide relevant veterinary documentation. We reserve the right to decline services when grooming would, in our professional judgment, pose a health risk.",
                    ),
                    _buildPolicyBullet(
                      title: "Senior dogs (first visit aged 12+)",
                      description:
                          "For dogs 12 years and older attending our salon for the first time, a veterinary report covering the past 12 months is required. This helps us assess safety and comfort; we may respectfully decline service if the report indicates significant risk.",
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "All policies are in place to protect your pet and all animals in our care. If service is declined, we will explain our concerns and, when possible, suggest safer alternatives or recommend consulting your veterinarian. For questions or assistance with documentation, please contact us.",
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => context.go('/policy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF536754),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          "Read Grooming Policy",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ================= 3. AUTO-SLIDING GALLERY =================
          Container(
            color: const Color(0xFFF7E6DC),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: isMobile ? 380 : 520,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 50 : 80,
                    ),
                    itemCount: (imagePaths.length / 4).ceil(),
                    itemBuilder: (context, index) {
                      final startIndex = index * 4;
                      final endIndex = (startIndex + 4 > imagePaths.length)
                          ? imagePaths.length
                          : startIndex + 4;
                      final blockImages = imagePaths.sublist(startIndex, endIndex);

                      return Container(
                        margin: EdgeInsets.only(right: isMobile ? 16 : 32),
                        width: isMobile ? 320 : 480,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: blockImages.length,
                          itemBuilder: (context, imgIndex) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                blockImages[imgIndex],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.pets, color: Colors.grey),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  left: isMobile ? 4 : 16,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 36, color: Colors.black87),
                      onPressed: () => _manualScroll(-450),
                    ),
                  ),
                ),

                Positioned(
                  right: isMobile ? 4 : 16,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 36, color: Colors.black87),
                      onPressed: () => _manualScroll(450),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPolicyBullet({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(
                    text: "$title\n",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}