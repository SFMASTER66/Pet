import 'package:flutter/material.dart';

class MerchantConfig {
  final String businessName;
  final String logoIcon;
  final int primaryColorValue;
  final List<String> tags;
  final Map<String, String> uiDictionary;

  MerchantConfig({
    required this.businessName,
    required this.logoIcon,
    required this.primaryColorValue,
    required this.tags,
    required this.uiDictionary,
  });

  /// 🔗 GETTER FOR MAIN.DART URL ROUTING
  /// Automatically transforms "Petcloud Grooming" into "petcloud-grooming"
  String get slug {
    return businessName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Color get primaryColor => Color(primaryColorValue);

  String getTxt(String key, String fallback) {
    return uiDictionary[key] ?? fallback;
  }

  factory MerchantConfig.fromMap(Map<String, dynamic> map) {
    // 1. Safely extract and parse the primary color
    int parsedColor = 0xFF0F766E; // Default fallback color
    
    if (map['primaryColor'] != null) {
      final rawColor = map['primaryColor'];
      if (rawColor is int) {
        parsedColor = rawColor;
      } else if (rawColor is String) {
        // Safely parse a numeric string (e.g., "4279203438") or a hex string
        parsedColor = int.tryParse(rawColor) ?? 
                      int.tryParse(rawColor.replaceAll('#', '').replaceAll('0x', ''), radix: 16) ?? 
                      0xFF0F766E;
      }
    }

    // 2. Return the cleanly initialized object
    return MerchantConfig(
      businessName: map['businessName'] ?? 'Paws & Claws Smart SPA Lounge',
      logoIcon: map['logoIcon'] ?? '🐶',
      primaryColorValue: parsedColor,
      tags: List<String>.from(map['tags'] ?? []),
      uiDictionary: Map<String, String>.from(map['uiDictionary'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logoIcon': logoIcon,
      'primaryColor': primaryColorValue,
      'tags': tags,
      'uiDictionary': uiDictionary,
    };
  }
}