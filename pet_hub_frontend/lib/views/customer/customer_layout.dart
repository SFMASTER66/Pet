import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';

enum CustomerTab { home, service, policy, book, contact, career }

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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        centerTitle: false,
        iconTheme: IconThemeData(color: config.primaryColor),
        title: InkWell(
          onTap: () => context.go('/customer'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(config.logoIcon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  config.businessName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: config.primaryColor,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: isMobile
            ? null
            : [
                _navBtn(context, 'Home', '/customer', activeTab == CustomerTab.home),
                _navBtn(context, 'Service', '/customer/service', activeTab == CustomerTab.service),
                _navBtn(context, 'Our Policy', '/customer/policy', activeTab == CustomerTab.policy),
                _navBtn(context, 'Book', '/customer/book', activeTab == CustomerTab.book),
                _navBtn(context, 'Contact', '/customer/contact', activeTab == CustomerTab.contact),
                _navBtn(context, 'Career', '/customer/career', activeTab == CustomerTab.career),
                const SizedBox(width: 16),
              ],
      ),
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  child,
                  const SizedBox(height: 40),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "© ${DateTime.now().year} ${config.businessName}. All rights reserved.",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(BuildContext context, String title, String route, bool isActive) {
    return TextButton(
      onPressed: () => context.go(route),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? config.primaryColor : const Color(0xFF475569),
          decoration: isActive ? TextDecoration.underline : TextDecoration.none,
        ),
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
                Text(config.logoIcon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  config.businessName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _drawerItem(context, 'Home', Icons.home, '/customer', activeTab == CustomerTab.home),
          _drawerItem(context, 'Service', Icons.cleaning_services, '/customer/service', activeTab == CustomerTab.service),
          _drawerItem(context, 'Our Policy', Icons.policy, '/customer/policy', activeTab == CustomerTab.policy),
          _drawerItem(context, 'Book', Icons.calendar_today, '/customer/book', activeTab == CustomerTab.book),
          _drawerItem(context, 'Contact', Icons.contact_support, '/customer/contact', activeTab == CustomerTab.contact),
          _drawerItem(context, 'Career', Icons.work, '/customer/career', activeTab == CustomerTab.career),
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