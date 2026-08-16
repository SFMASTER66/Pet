import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerFooter extends StatelessWidget {
  const CustomerFooter({super.key});

  Future<void> _openPdfInNewTab(String relativePath) async {
    // Resolve path against current base URL (e.g. http://localhost:3000)
    final Uri absoluteUrl = Uri.base.resolve(relativePath);

    try {
      final bool launched = await launchUrl(
        absoluteUrl,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!launched) {
        debugPrint('⚠️ Could not launch $absoluteUrl');
      }
    } catch (e) {
      debugPrint('⚠️ Error launching PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    const headerColor = Color(0xFF91A382);
    const textColor = Color(0xFF333333);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: 40,
        horizontal: isMobile ? 24 : 64,
      ),
      child: Column(
        children: [
          // Store Name Header
          const Text(
            "PAWPARAZZI PET Boutique Store",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // Responsive Section Columns
          Wrap(
            alignment: WrapAlignment.spaceAround,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 32,
            runSpacing: 32,
            children: [
              // Column 1: Contact
              SizedBox(
                width: isMobile ? screenWidth : 220,
                child: Column(
                  children: [
                    const Text(
                      "Contact",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "contact@pawparazzipet.com.au",
                      style: TextStyle(fontSize: 14, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "0493707378",
                      style: TextStyle(fontSize: 14, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        // Add Instagram redirect URL logic here
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Column 2: Location
              SizedBox(
                width: isMobile ? screenWidth : 220,
                child: const Column(
                  children: [
                    Text(
                      "Location",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Shop 64 30 lonsdale street,\nBraddon ACT 2612",
                      style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Column 3: Operation Hours
              SizedBox(
                width: isMobile ? screenWidth : 250,
                child: const Column(
                  children: [
                    Text(
                      "Operation hours",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Mon - Sat 10:00 - 17:00",
                      style: TextStyle(fontSize: 14, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "(grooming 09:00 - 17:00)",
                      style: TextStyle(fontSize: 14, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Close on Suns & Public Holidays",
                      style: TextStyle(fontSize: 14, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Column 4: Policy Links
              SizedBox(
                width: isMobile ? screenWidth : 220,
                child: Column(
                  crossAxisAlignment:
                      isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    _buildFooterLink(
                      label: "Terms and Conditions",
                      onTap: () => context.go('/about-terms-conditions'),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink(
                      label: "Grooming Agreement",
                      onTap: () => _openPdfInNewTab('assets/grooming_agreement.pdf'),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink(
                      label: "Booking Cancellation Policy",
                      onTap: () => context.go('/about-cancellation-policy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF333333),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}