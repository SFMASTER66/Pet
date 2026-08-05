import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'views/auth_wrapper.dart'; 
import 'models/merchant_config.dart';
import 'views/business_dashboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'config/app_config.dart';

// Customer view imports
import 'views/customer/customer_home_page.dart';
import 'views/customer/customer_services_page.dart';
import 'views/customer/customer_policy_page.dart';
import 'views/customer/customer_book_page.dart';
import 'views/customer/customer_contact_page.dart';
import 'views/customer/customer_career_page.dart';

String? jwtToken;
bool isAdmin = false; 
late MerchantConfig globalMerchantConfig;
late SharedPreferences prefs;

const String kBaseUrl = 'http://localhost:8080';

final GoRouter _router = GoRouter(
  initialLocation: '/', 
  
  redirect: (BuildContext context, GoRouterState state) {
    final bool loggingIn = state.matchedLocation == '/api/v1/login' || 
                           state.matchedLocation == '/api/v1/register';

    jwtToken ??= prefs.getString('jwt_token');
    if (prefs.containsKey('is_admin') && jwtToken != null) {
      isAdmin = isAdmin || (prefs.getBool('is_admin') ?? false); 
    }
    
    // Allow public access to all customer routes (non-API routes)
    final bool isCustomerRoute = !state.matchedLocation.startsWith('/api/v1');

    if (jwtToken == null) {
      if (loggingIn || isCustomerRoute) {
        return null;
      }
      return '/api/v1/login';
    }

    if (loggingIn) {
      final String rawBusinessName = globalMerchantConfig.businessName;
      final String businessSlug = rawBusinessName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
      return '/api/v1/$businessSlug/dashboard';
    }

    return null;
  },

  routes: [
    // ---------------- Customer Routes ----------------
    // Root landing page (Home)
    GoRoute(
      path: '/',
      builder: (context, state) => CustomerHomePage(
        config: globalMerchantConfig,
        baseUrl: kBaseUrl,
      ),
    ),
    // Service route
    GoRoute(
      path: '/service',
      builder: (context, state) => CustomerServicesPage(
        config: globalMerchantConfig,
      ),
    ),
    // Booking route
    GoRoute(
      path: '/book',
      builder: (context, state) => CustomerBookPage(
        config: globalMerchantConfig,
        baseUrl: kBaseUrl,
      ),
    ),
    // Policy route
    GoRoute(
      path: '/policy',
      builder: (context, state) => CustomerPolicyPage(
        config: globalMerchantConfig,
      ),
    ),
    // Contact route
    GoRoute(
      path: '/contact',
      builder: (context, state) => CustomerContactPage(
        config: globalMerchantConfig,
      ),
    ),
    // Career route
    GoRoute(
      path: '/career',
      builder: (context, state) => CustomerCareerPage(
        config: globalMerchantConfig,
      ),
    ),

    // ---------------- Merchant Routes ----------------
    GoRoute(
      path: '/api/v1/login',
      builder: (context, state) => MerchantAuthWrapper(
        isRegisterMode: false,
        onUpdateAuth: _handleAuthUpdate,
      ),
    ),
    GoRoute(
      path: '/api/v1/register',
      builder: (context, state) => MerchantAuthWrapper(
        isRegisterMode: true,
        onUpdateAuth: _handleAuthUpdate,
      ),
    ),
    GoRoute(
      path: '/api/v1/:businessName/dashboard', 
      builder: (context, state) {
        return UnifiedMerchantDashboard(
          config: globalMerchantConfig,
          authToken: jwtToken ?? '', 
          isAdmin: isAdmin,
          onLogout: () async {
            await prefs.remove('jwt_token');
            await prefs.remove('cached_config');
            await prefs.remove('is_admin');
            jwtToken = null; 
            isAdmin = false;
            
            if (context.mounted) {
              context.go('/api/v1/login'); 
            }
          },
          onConfigChanged: (updatedConfig) async {
            globalMerchantConfig = updatedConfig;
            await prefs.setString('cached_config', jsonEncode(updatedConfig.toJson()));
          },
        );
      },
    ),
  ],
);

Future<void> _handleAuthUpdate(String token, String role, Map<String, dynamic> configPayload) async {
  jwtToken = token;
  isAdmin = (role == 'MERCHANT_ADMIN');
  globalMerchantConfig = MerchantConfig.fromJson(configPayload);

  await prefs.setString('jwt_token', token);
  await prefs.setBool('is_admin', isAdmin);
  await prefs.setString('cached_config', jsonEncode(configPayload));

  final String businessSlug = globalMerchantConfig.businessName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  _router.go('/api/v1/$businessSlug/dashboard');
}

void main() async {
  usePathUrlStrategy(); 
  WidgetsFlutterBinding.ensureInitialized(); 

  Stripe.publishableKey = AppConfig.stripePublishableKey;

  if (!kIsWeb) {
    Stripe.merchantIdentifier = AppConfig.merchantIdentifier;
    Stripe.urlScheme = AppConfig.urlScheme;
  }

  try {
    await Stripe.instance.applySettings();
  } catch (e) {
    debugPrint("⚠️ Stripe applySettings notice: $e");
  }

  prefs = await SharedPreferences.getInstance();

  final String? cachedConfigJson = prefs.getString('cached_config');
  if (cachedConfigJson != null) {
    try {
      globalMerchantConfig = MerchantConfig.fromJson(jsonDecode(cachedConfigJson));
    } catch (_) {
      _loadDefaultConfig();
    }
  } else {
    _loadDefaultConfig();
  }

  runApp(const MyApp());
}

void _loadDefaultConfig() {
  globalMerchantConfig = MerchantConfig.fromJson({
    'businessName': 'My Workspace',
    'logoIcon': '💼',
    'primaryColor': '0xFF1E293B',
    'tags': ['General'],
    'uiDictionary': {
      'btn_book': 'Book Appointment (Manual)',
      'btn_cancel': 'Release Timeslot (Cancel)',
      'btn_edit': 'Reschedule Appointment',
      'txt_revenue': 'Estimated Daily Revenue'
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}