import 'package:flutter/material.dart';

class MerchantConfig {
  final String merchantId; // ✨ explicitly tracked property
  final String businessName;
  final String logoIcon;
  final int primaryColorValue;
  final List<String> tags;
  final Map<String, String> uiDictionary;

  MerchantConfig({
    required this.merchantId,
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
    // 1. Extract Merchant ID from various possible payload positions
    String extractedMerchantId = '1';
    if (map['merchantId'] != null) {
      extractedMerchantId = map['merchantId'].toString();
    } else if (map['id'] != null) {
      extractedMerchantId = map['id'].toString();
    } else if (map['uiDictionary'] != null && map['uiDictionary']['merchantId'] != null) {
      extractedMerchantId = map['uiDictionary']['merchantId'].toString();
    }

    // 2. Safely extract and parse the primary color
    int parsedColor = 0xFF0F766E; // Default fallback color
    if (map['primaryColor'] != null) {
      final rawColor = map['primaryColor'];
      if (rawColor is int) {
        parsedColor = rawColor;
      } else if (rawColor is String) {
        parsedColor = int.tryParse(rawColor) ?? 
                      int.tryParse(rawColor.replaceAll('#', '').replaceAll('0x', ''), radix: 16) ?? 
                      0xFF0F766E;
      }
    }

    // 3. Build dictionary ensuring the merchantId is stored inside it too
    final Map<String, String> rawUiDict = {};
    if (map['uiDictionary'] != null) {
      (map['uiDictionary'] as Map).forEach((k, v) {
        rawUiDict[k.toString()] = v.toString();
      });
    }
    rawUiDict['merchantId'] = extractedMerchantId;

    // 4. Return the cleanly initialized object
    return MerchantConfig(
      merchantId: extractedMerchantId,
      businessName: map['businessName'] ?? 'Paws & Claws Smart SPA Lounge',
      logoIcon: map['logoIcon'] ?? '🐶',
      primaryColorValue: parsedColor,
      tags: List<String>.from(map['tags'] ?? []),
      uiDictionary: rawUiDict,
    );
  }

  /// ✨ ADD THIS METHOD TO FIX THE COMPILATION ERROR
  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'businessName': businessName,
      'logoIcon': logoIcon,
      'primaryColor': primaryColorValue,
      'tags': tags,
      'uiDictionary': uiDictionary,
    };
  }
}