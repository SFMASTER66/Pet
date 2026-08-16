import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerCancellationPolicyPage extends StatelessWidget {
  final MerchantConfig config;

  const CustomerCancellationPolicyPage({super.key, required this.config});

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
                      "GROOMING BOOKING CANCELLATION POLICY",
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

                    // Light yellow card background matching the policy page
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
                            "At Pawparazzi Pet, we strive to provide exceptional service to our valued clients and their furry companions. To ensure smooth operations and fairness to all, we have established the following cancellation policy:",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF475569),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Bullet 1
                          _buildBulletItem(
                            "Cancellations or rescheduling requests made with over 24 hours notice before the scheduled appointment will incur no charges. You are welcome to reschedule your appointment at no additional cost.",
                          ),
                          const SizedBox(height: 16),

                          // Bullet 2
                          _buildBulletItem(
                            "Cancellations or rescheduling requests made less than 24 hours before the scheduled appointment will result in forfeiture of the \$30 deposit. Unfortunately, we cannot issue refunds for cancellations me within this time frame.",
                          ),
                          const SizedBox(height: 16),

                          // Bullet 3
                          _buildBulletItem(
                            "In the event of a no-show, where a client fails to attend the scheduled appointment without prior notice, the \$30 deposit will be retained, and no refunds will be provided.",
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            "We appreciate your understanding and cooperation with our cancellation policy. If you have any questions or need further assistance, please do not hesitate to contact us.",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF475569),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            "Thank you for choosing Pawparazzi Pet for your pet's grooming needs.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF475569),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Highlighted Note
                          const Text(
                            "*Cancellations made with more than 24 hours' notice are eligible for a refund. But a 3% payment processing fee is non-refundable.*",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Color(0xFF1E293B),
                              height: 1.5,
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
}