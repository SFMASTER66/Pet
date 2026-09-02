import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';
import 'customer_footer.dart';
import 'dart:convert';

enum CustomerTab { home, service, policy, book, contact, career, none }

class CustomerLayoutWrapper extends StatelessWidget {
  final MerchantConfig config;
  final CustomerTab activeTab;
  final Widget child;

  const CustomerLayoutWrapper({
    super.key,
    required this.config,
    required this.activeTab,
    required this.child,
  });

  // Helper function to dynamically render the logo as an Image or Text
  Widget _buildLogoWidget(String logoIcon, {double size = 140.0}) {
    final cleanPath = logoIcon.trim();
    final lower = cleanPath.toLowerCase();

    if (cleanPath.isEmpty) {
      return Icon(Icons.pets, size: size, color: config.primaryColor);
    }

    // 1. Handle Network Images
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return Image.network(
        cleanPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Network logo failed to load ($cleanPath): $error');
          return Icon(Icons.pets, size: size, color: config.primaryColor);
        },
      );
    }

    // 2. Handle Local Assets
    final isImageAsset = lower.startsWith('assets/') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg');

    if (isImageAsset) {
      final assetPath = lower.startsWith('assets/') ? cleanPath : 'assets/$cleanPath';

      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Asset logo failed to load at path "$assetPath". Error: $error');
          return Icon(Icons.pets, size: size, color: config.primaryColor);
        },
      );
    }

    // 3. Handle Base64 Image Strings (Prevents text explosion and FormatExceptions)
    final isBase64 = lower.startsWith('data:image') || cleanPath.contains(',') || cleanPath.length > 50;

    if (isBase64) {
      try {
        final base64String = cleanPath.contains(',') ? cleanPath.split(',').last : cleanPath;
        return Image.memory(
          base64Decode(base64String),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Base64 image rendering failed: $error');
            return Icon(Icons.pets, size: size, color: config.primaryColor);
          },
        );
      } catch (e) {
        debugPrint('❌ Base64 decoding failed: $e');
        return Icon(Icons.pets, size: size, color: config.primaryColor);
      }
    }

    // 4. Fallback for Emojis or Plain Text Icons
    return Text(
      cleanPath,
      style: TextStyle(fontSize: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER SECTION
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Mobile Top App Bar with Drawer Icon
                    if (isMobile)
                      Builder(
                        builder: (context) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.menu, color: config.primaryColor),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => context.go('/'),
                                child: _buildLogoWidget(config.logoIcon, size: 65),
                              ),
                              const Spacer(),
                              const SizedBox(width: 48), // Balance drawer icon
                            ],
                          ),
                        ),
                      )
                    else
                      // Desktop/Tablet Centered Header Layout
                      Padding(
                        padding: const EdgeInsets.only(top: 28.0, bottom: 16.0),
                        child: Center(
                          child: InkWell(
                            onTap: () => context.go('/'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLogoWidget(config.logoIcon, size: 140),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Divider Line above Nav Bar
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                    // Navigation Bar (Desktop / Tablet)
                    if (!isMobile)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _navBtn(context, 'Home', '/', activeTab == CustomerTab.home),
                            const SizedBox(width: 28),
                            _navBtn(context, 'Service', '/service', activeTab == CustomerTab.service),
                            const SizedBox(width: 28),
                            _navBtn(context, 'Our Policy', '/policy', activeTab == CustomerTab.policy),
                            const SizedBox(width: 28),
                            _navBtn(context, 'Book', '/book', activeTab == CustomerTab.book),
                            const SizedBox(width: 28),
                            _navBtn(context, 'Contact', '/contact', activeTab == CustomerTab.contact),
                            const SizedBox(width: 28),
                            _navBtn(context, 'Career', '/career', activeTab == CustomerTab.career),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // MAIN CONTENT SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        child,
                        const SizedBox(height: 40),
                        // Footer section
                        const CustomerFooter(),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        // "All rights reserved" placed below the footer
                        Text(
                          "© ${DateTime.now().year} ${config.businessName}. All rights reserved.",
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(BuildContext context, String title, String route, bool isActive) {
    return InkWell(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top indicator line matching screenshot style
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? config.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? const Color(0xFF1E293B) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: config.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoWidget(config.logoIcon, size: 60),
                const SizedBox(height: 8),
                Text(
                  config.businessName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _drawerItem(context, 'Home', Icons.home, '/', activeTab == CustomerTab.home),
          _drawerItem(context, 'Service', Icons.cleaning_services, '/service', activeTab == CustomerTab.service),
          _drawerItem(context, 'Our Policy', Icons.policy, '/policy', activeTab == CustomerTab.policy),
          _drawerItem(context, 'Book', Icons.calendar_today, '/book', activeTab == CustomerTab.book),
          _drawerItem(context, 'Contact', Icons.contact_support, '/contact', activeTab == CustomerTab.contact),
          _drawerItem(context, 'Career', Icons.work, '/career', activeTab == CustomerTab.career),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String title, IconData icon, String route, bool isActive) {
    return ListTile(
      leading: Icon(icon, color: isActive ? config.primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? config.primaryColor : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}