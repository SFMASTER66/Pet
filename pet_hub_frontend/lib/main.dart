import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'views/auth_wrapper.dart'; 
import 'models/merchant_config.dart';
import 'views/business_dashboard.dart';

String? jwtToken;
bool isAdmin = false; // 👈 Track dashboard permission context globally
late MerchantConfig globalMerchantConfig;
late SharedPreferences prefs;

final GoRouter _router = GoRouter(
  initialLocation: '/api/v1/login',
  
  redirect: (BuildContext context, GoRouterState state) {
    final bool loggingIn = state.matchedLocation == '/api/v1/login' || 
                           state.matchedLocation == '/api/v1/register';

    jwtToken = prefs.getString('jwt_token');
    isAdmin = prefs.getBool('is_admin') ?? false; // 👈 Revive role profile from storage cache
    
    if (jwtToken == null) {
      if (loggingIn) return null;
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
    GoRoute(
      path: '/api/v1/login',
      builder: (context, state) => MerchantAuthWrapper(
        isRegisterMode: false,
        onUpdateAuth: _handleAuthUpdate, // 👈 Handled via explicit functional callback method
      ),
    ),
    GoRoute(
      path: '/api/v1/register',
      builder: (context, state) => MerchantAuthWrapper(
        isRegisterMode: true,
        onUpdateAuth: _handleAuthUpdate, // 👈 Handled via explicit functional callback method
      ),
    ),
    GoRoute(
      path: '/api/v1/:businessName/dashboard', 
      builder: (context, state) {
        return UnifiedMerchantDashboard(
          config: globalMerchantConfig,
          authToken: jwtToken ?? '', 
          isAdmin: isAdmin, // 👈 FIXED: Parameter successfully injected 
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
            await prefs.setString('cached_config', jsonEncode(updatedConfig.toMap()));
          },
        );
      },
    ),
  ],
);

// Unified centralized authorization updates orchestrator execution block
Future<void> _handleAuthUpdate(String token, String role, Map<String, dynamic> configPayload) async {
  jwtToken = token;
  isAdmin = (role == 'MERCHANT_ADMIN');
  globalMerchantConfig = MerchantConfig.fromMap(configPayload);

  // Synchronize dynamic elements into structural device safe preference caches
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
  
  prefs = await SharedPreferences.getInstance();

  final String? cachedConfigJson = prefs.getString('cached_config');
  if (cachedConfigJson != null) {
    try {
      globalMerchantConfig = MerchantConfig.fromMap(jsonDecode(cachedConfigJson));
    } catch (_) {
      _loadDefaultConfig();
    }
  } else {
    _loadDefaultConfig();
  }

  runApp(const MyApp());
}

void _loadDefaultConfig() {
  globalMerchantConfig = MerchantConfig.fromMap({
    'businessName': 'My Workspace',
    'logoIcon': '💼',
    'primaryColor': 0xFF1E293B,
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