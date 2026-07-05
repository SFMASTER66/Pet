import 'package:flutter/material.dart';

class MerchantConfig {
  final String merchantId;
  // ========================================================
  // 🔥 HIGHLIGHT: ADDED THE USERID PROPERTY DECLARATION
  // ========================================================
  final String userId; 
  final String businessName;
  final String logoIcon;
  final String primaryColorValue;
  final List<String> tags;
  final Map<String, dynamic> uiDictionary;

  MerchantConfig({
    required this.merchantId,
    required this.userId, // 👈 Required in constructor
    required this.businessName,
    required this.logoIcon,
    required this.primaryColorValue,
    required this.tags,
    this.uiDictionary = const {},
  });

  /// Helper factory to instantiate configurations straight out of backend HTTP JSON streams
  factory MerchantConfig.fromJson(Map<String, dynamic> json) {
    return MerchantConfig(
      merchantId: json['merchantId'] ?? '',
      // ========================================================
      // 🔥 HIGHLIGHT: EXTRACT USERID SAFELY FROM THE JSON PAYLOAD
      // ========================================================
      userId: json['userId'] ?? '', 
      businessName: json['businessName'] ?? 'Pet Workspace Tenant',
      logoIcon: json['logoIcon'] ?? '🐾',
      primaryColorValue: json['primaryColor'] ?? '0xFF0F766E',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      uiDictionary: json['uiDictionary'] ?? {},
    );
  }

  /// Helper instance converter mapping fields back into a clean flat Map payload
  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'userId': userId, // 👈 Serialize out to persistent local caching profiles if needed
      'businessName': businessName,
      'logoIcon': logoIcon,
      'primaryColor': primaryColorValue,
      'tags': tags,
      'uiDictionary': uiDictionary,
    };
  }

  /// Parses the database color hex string value into a Flutter safe visual UI Color asset
  Color get primaryColor {
    try {
      return Color(int.parse(primaryColorValue));
    } catch (_) {
      return const Color(0xFF0F766E); // Safe fallback asset layout
    }
  }

  /// Localization text fallback matrix dictionary lookups
  String getTxt(String targetKey, String fallbackMessage) {
    return uiDictionary[targetKey] ?? fallbackMessage;
  }
}