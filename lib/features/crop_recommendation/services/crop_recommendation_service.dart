import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/models/crop_input_data.dart';

class CropRecommendationEngine {
  static List<Map<String, dynamic>>? _cropsDatabase;

  /// STEP 9: Compute once, avoid repeated calculations.
  /// Load crop database from JSON
  static Future<void> initDatabase() async {
    if (_cropsDatabase != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/crops.json');
      final data = jsonDecode(jsonString);
      _cropsDatabase = List<Map<String, dynamic>>.from(data['crops']);
    } catch (e) {
      _cropsDatabase = [];
      debugPrint("Error loading crops.json: $e");
    }
  }

  /// STEP 1: Convert NPK Values
  static String _getNitrogenLevel(double n) {
    if (n < 100) return 'low';
    if (n <= 250) return 'medium';
    return 'high';
  }

  static String _getPhosphorusLevel(double p) {
    if (p < 30) return 'low';
    if (p <= 60) return 'medium';
    return 'high';
  }

  static String _getPotassiumLevel(double k) {
    if (k < 100) return 'low';
    if (k <= 250) return 'medium';
    return 'high';
  }

  /// Compute compatibility logic between crop level and user level
  static double _matchLevel(String cropLevel, String userLevel) {
    if (cropLevel == userLevel) return 1.0; // full match
    // Partial Match: if e.g. medium vs low/high, difference is 1 step
    bool isPartial = (cropLevel == 'medium' || userLevel == 'medium');
    if (isPartial) return 0.5; // half score
    return 0.0; // no match (low vs high)
  }

  static Future<List<Map<String, dynamic>>> getRecommendations(CropInputData input) async {
    await initDatabase();
    
    // Normalize user NPK levels
    String? userN = input.nLevel?.toLowerCase();
    if (input.nitrogen != null) userN = _getNitrogenLevel(input.nitrogen!);

    String? userP = input.pLevel?.toLowerCase();
    if (input.phosphorus != null) userP = _getPhosphorusLevel(input.phosphorus!);

    String? userK = input.kLevel?.toLowerCase();
    if (input.potassium != null) userK = _getPotassiumLevel(input.potassium!);

    List<Map<String, dynamic>> results = [];

    for (var crop in _cropsDatabase!) {
      double score = 0;

      // STEP 3 & 4: Scoring System
      
      // Soil match -> +20
      if (crop['soil'] != null) {
        List<dynamic> cropSoils = crop['soil'];
        String userSoil = input.normalizedSoilType;
        if (cropSoils.contains(userSoil)) {
          score += 20;
        } else if (cropSoils.any((s) => s.toString().contains(userSoil) || userSoil.contains(s.toString()))) {
          score += 10;
        }
      }

      // pH match -> +15
      if (crop['ph'] != null && input.ph != null) {
        double minPh = (crop['ph'][0] as num).toDouble();
        double maxPh = (crop['ph'][1] as num).toDouble();
        if (input.ph! >= minPh && input.ph! <= maxPh) {
          score += 15;
        } else if ((input.ph! - minPh).abs() <= 0.5 || (input.ph! - maxPh).abs() <= 0.5) {
          score += 7.5;
        }
      } else if (input.ph == null) {
        // Unknown user pH -> partial
        score += 7.5;
      }

      // Temperature match -> +15
      if (crop['temp'] != null && input.temperature != null) {
        double minT = (crop['temp'][0] as num).toDouble();
        double maxT = (crop['temp'][1] as num).toDouble();
        if (input.temperature! >= minT && input.temperature! <= maxT) {
          score += 15;
        } else if ((input.temperature! - minT).abs() <= 2.0 || (input.temperature! - maxT).abs() <= 2.0) {
          score += 7.5;
        }
      } else if (input.temperature == null) {
        score += 7.5;
      }

      // Season match -> +10
      if (crop['season'] != null) {
        List<dynamic> cropSeasons = crop['season'];
        String userSeason = input.normalizedSeason;
        if (cropSeasons.contains(userSeason) || cropSeasons.contains('annual')) {
          score += 10;
        } else if (cropSeasons.any((s) => s.toString().contains(userSeason) || userSeason.contains(s.toString()))) {
          score += 5;
        }
      }

      // Water/Irrigation match -> +10
      if (crop['water'] != null) {
        String cropWater = crop['water'].toString().toLowerCase();
        bool userHasIrrigation = input.normalizedIrrigation.isNotEmpty;
        
        if (cropWater == 'low') {
          score += 10;
        } else if (cropWater == 'medium') {
          score += userHasIrrigation ? 10 : 5;
        } else if (cropWater == 'high') {
          score += userHasIrrigation ? 10 : 0;
        }
      }

      // N match -> +10
      if (crop['n'] != null && userN != null) {
        score += 10 * _matchLevel(crop['n'].toString().toLowerCase(), userN);
      } else if (userN == null) {
        score += 5;
      }

      // P match -> +10
      if (crop['p'] != null && userP != null) {
        score += 10 * _matchLevel(crop['p'].toString().toLowerCase(), userP);
      } else if (userP == null) {
        score += 5;
      }

      // K match -> +10
      if (crop['k'] != null && userK != null) {
        score += 10 * _matchLevel(crop['k'].toString().toLowerCase(), userK);
      } else if (userK == null) {
        score += 5;
      }

      // STEP 5: Profit Boost -> +5
      if (crop['profit']?.toString().toLowerCase() == 'high') {
        score += 5;
      }

      // Cap at 100
      if (score > 100) score = 100;

      // Parse tags
      List<String> tags = [];
      if (crop['profit']?.toString().toLowerCase() == 'high') tags.add('High Profit');
      if (crop['water']?.toString().toLowerCase() == 'low') tags.add('Low Water');
      if (crop['water']?.toString().toLowerCase() == 'medium') tags.add('Medium Water');
      
      results.add({
        "name": crop['name'],
        "score": score,
        "confidence": "${score.toStringAsFixed(0)}%",
        "tags": tags,
        "imageUrl": crop['imageUrl'] ?? "",
      });
    }

    // STEP 6: Sort Crops (descending)
    results.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

    // STEP 7: Return top 5
    return results.take(5).toList();
  }
}
