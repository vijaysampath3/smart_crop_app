import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../models/crop.dart';
import '../models/crop_ai_guide.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/models/crop_input_data.dart';

class CropAiService {
  // Simple in-memory cache to store responses per combination
  static final Map<String, CropAiGuide> _cache = {};

  static Future<CropAiGuide> fetchCropGuide({
    required Crop crop,
    required CropInputData inputData,
  }) async {
    // Construct cache key
    final cacheKey = "${crop.id}_${inputData.location}_${inputData.soilType}_${inputData.ph}_${inputData.season}_${inputData.irrigation.join('-')}";

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    if (AppConfig.openAiApiKey == "YOUR_OPENAI_API_KEY") {
      throw Exception("OpenAI API key missing. Please configure it in app_config.dart.");
    }

    final String prompt = '''
You are an expert agronomist providing tailored farming guidance.
Crop: ${crop.name} (${crop.scientificName})
Location: ${inputData.location.isNotEmpty ? inputData.location : 'Unknown'}
Soil: ${inputData.soilType}
pH: ${inputData.ph ?? 'Unknown'}
Irrigation: ${inputData.irrigation.isNotEmpty ? inputData.irrigation.join(', ') : 'Unknown'}
Season: ${inputData.season}

Based on these inputs, generate a structured guide for cultivating ${crop.name}.
Return ONLY valid JSON matching this structure:
{
  "growingStages": [{"title": "Stage Name", "subtitle": "Short instruction"}],
  "farmingMethods": ["Method 1", "Method 2"],
  "fertilizer": {
    "n": "Nitrogen kg/ha", "p": "Phosphorus kg/ha", "k": "Potassium kg/ha"
  },
  "pestPrevention": [{"emoji": "🐛", "title": "Pest Name", "subtitle": "Prevention instruction"}],
  "marketDemand": {"price": "₹XX/kg", "demandLevel": "High/Med/Low", "bestSeason": "Months"},
  "tips": ["Tip 1", "Tip 2"]
}
''';

    final uri = Uri.parse("https://models.inference.ai.azure.com/chat/completions");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppConfig.openAiApiKey}",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "system", "content": "You are a helpful agronomist. Always output valid JSON only."},
          {"role": "user", "content": prompt}
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'];
      
      final guideMap = jsonDecode(content) as Map<String, dynamic>;
      final guide = CropAiGuide.fromJson(guideMap);
      
      _cache[cacheKey] = guide;
      return guide;
    } else {
      throw Exception("Failed to load AI guidance. Status: ${response.statusCode}\nBody: ${response.body}");
    }
  }
}
