import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerTermsConditionsPage extends StatelessWidget {
  final MerchantConfig config;

  const CustomerTermsConditionsPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.policy,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isDesktop = constraints.maxWidth > 900;

          final horizontalPadding = isMobile
              ? 16.0
              : isDesktop
                  ? 48.0
                  : 32.0;
          final titleFontSize = isMobile ? 22.0 : 30.0;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 850),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "PAWPARAZZI PET GROOMING TERMS AND CONDITIONS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4C5844),
                        letterSpacing: 1.1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Light yellow card container matching other policy pages
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "At Pawparazzi Pet, we strive to provide exceptional dog grooming services while ensuring the safety, well-being, and comfort of all the dogs in our care. To maintain a positive and safe environment, we have established the following dog grooming policy:",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF475569),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildBulletItem(
                            "Appointments should be scheduled in advance to ensure availability. Walk-in bookings may be accommodated based on availability.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "Pets must be in good health and free from any contagious illnesses, if your pet has special needs or medical conditions, please inform us in advance. Aggressive or overly anxious pets may require special handling or may not be able to receive certain services.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "Please note that the price list is for reference only, and the final price depends on the size, breed and coat of pets and the time required for grooming. If your pet is uncooperative or the need for additional services may incur additional charges.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "All dogs must be up to date on vaccinations. If your dog is unwell, has a contagious condition, or is exhibiting signs of illness, we may refuse grooming services to protect the health of other dogs in our facility.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "If fleas or ticks are found during grooming, we will use appropriate treatments. An additional fee may be applied.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "We will do our best to accommodate any special requests, but please understand that certain limitations may apply based on your dog's breed, coat condition, temperament, or specific grooming needs. If you have preference, please provide specific instructions for your desired grooming style. Pictures are encouraged.Some breeds have standard grooming styles. Please let us know if you have a preference. We reserve the right to refuse any requests that may jeopardise the safety or well-being of the dog.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "Matted coats may require additional charges due to the increased difficulty and time required during grooming. If the matting is too severe or poses a risk to the dog's well-being, we may recommend shaving the coat for the dog's comfort and to prevent further matting and skin issues. We will always discuss this option with you before proceeding.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "We reserve the right to use muzzles or other appropriate tools to ensure the safety of our staff during grooming sessions. We may refuse or discontinue grooming services to over aggressive dogs to ensure the safety of our staff and other dogs.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "If your senior dog has mobility challenges, we will take extra precautions to ensure their safety. We may use non-slip mats or adjust the grooming table to reduce stress on their joints.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "Pawparazzi Pet is under 24-hour CCTV surveillance to ensure the safety of our team and pets.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "Owners must come to our store to pick up pets before closing or an additional fee will apply.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "Pawparazzi Pet reserves the right to refuse any appointment at our discretion.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItem(
                            "If you are not satisfied with the grooming service, please let us know within 24 hours, and we will do our best to address your concerns.",
                          ),
                          const SizedBox(height: 16),

                          _buildBulletItemWithBoldText(
                            prefix: "New clients need to sign ",
                            boldText: "\"Pawparazzi Grooming Agreement Form\"",
                            suffix: " at the store before accepting our service",
                          ),
                          const SizedBox(height: 28),

                          const Text(
                            "By utilizing our dog grooming services, you acknowledge that you have read, understood, and agreed to comply with the policies outlined above. We reserve the right to update or modify our dog grooming policy as needed and will provide notice of any changes.",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF475569),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Book Button
                          Center(
                            child: ElevatedButton(
                              onPressed: () => context.go('/book'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E6B56),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 16,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text('Book'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "• ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            height: 1.6,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItemWithBoldText({
    required String prefix,
    required String boldText,
    required String suffix,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "• ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            height: 1.6,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF475569),
                height: 1.6,
              ),
              children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: boldText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: Color(0xFF1E293B),
                  ),
                ),
                TextSpan(text: suffix),
              ],
            ),
          ),
        ),
      ],
    );
  }
}