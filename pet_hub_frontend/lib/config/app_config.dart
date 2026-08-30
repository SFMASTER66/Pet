import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class AppConfig {
  /// 1. Reads from command line parameter `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...`
  /// 2. Falls back to default key if no runtime flag is provided
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51P5Qn4LX4QZVeeSX2VhKc1D8KrC0RSLKSaIsesviWIbIKi9Hj4Kok2pucEixjdGTK8gqGuLY59sBjhowYmKC6Ymq00RPcM6lbt',
  );
  static const String merchantID = "a1132446-fe91-4d6e-8bb6-7aa61367f89f";

  static const String merchantIdentifier = 'merchant.com.yourdomain.app';
  static const String urlScheme = 'flutterstripe';

  // --- Backend API Configuration ---
  static const String _productionUrl = 'https://pet-backend-d2a7.onrender.com';

  /// Set to [true] to target live Render backend, or [false] for local testing
  static const bool isProduction = false;

  static String get baseUrl {
    if (isProduction) {
      return _productionUrl;
    }

    // Local Development Fallbacks
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }
}