import 'dart:convert';
import 'package:http/http.dart' as http;
import 'warehouse_plan_model.dart';
import 'package:smart_crop_assistant/core/config/app_secrets.dart';

class WarehousePlanService {
  // Using the same API key and endpoint format observed in the chat bot implementation 
  // to ensure functional continuity with existing app infrastructure.
  static const String _apiKey = AppSecrets.githubApiKey;
  
  Future<WarehousePlanResult> generatePlan(WarehousePlanInfo info) async {
    try {
      final response = await http.post(
        Uri.parse('https://models.inference.ai.azure.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'response_format': { "type": "json_object" },
          'messages': [
            {
              'role': 'system',
              'content': '''You are an expert agricultural warehouse planner for Indian farmers.
Generate a practical and realistic storage plan considering climate, cost, and the specific crop.
Also generate 2-3 alternative storage options based on crop, budget, and location. Keep them practical for Indian farmers.
IMPORTANT: You MUST return strictly valid JSON matching exactly this structure, nothing else:
{
  "type": "Recommended warehouse type",
  "dimensions": {
    "length": "string (e.g. 20 ft)",
    "width": "string (e.g. 15 ft)",
    "height": "string (e.g. 12 ft)"
  },
  "capacity": "string (e.g. 10 Tons)",
  "budget": "string (e.g. ₹ 1.2 Lakh)",
  "steps": ["step 1", "step 2", "step 3"],
  "tips": ["tip 1", "tip 2", "tip 3"],
  "alternatives": [
    {
      "title": "Short title",
      "description": "Short description"
    }
  ]
}'''
            },
            {
              'role': 'user',
              'content': 'Storage Location: ${info.location}, Capacity Required: ${info.capacity} tons, Construction Method: ${info.method}, Budget Range: ${info.budget}, Crop: ${info.crop}. Ensure output is JSON only.'
            },
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        // Parse the JSON string from OpenAI
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        return WarehousePlanResult.fromJson(jsonMap);
      } else {
        throw Exception('API Failed with status ${response.statusCode}');
      }
    } catch (e) {
      // Return a basic fallback plan as requested if API fails
      return WarehousePlanResult(
        type: 'Basic Storage Shed (Fallback)',
        dimensions: DimensionModel(length: '20 ft', width: '15 ft', height: '10 ft'),
        capacity: '${info.capacity} Tons',
        budget: info.budget,
        steps: [
          'Prepare and level the land',
          'Construct basic foundation',
          'Erect walls using preferred method',
          'Install roofing and ventilation'
        ],
        tips: [
          'Keep area clean and dry to prevent pests',
          'Ensure good cross ventilation',
          'Regularly check for moisture issues'
        ],
        alternatives: [
          AlternativeOption(title: 'Rent', description: 'Low upfront cost'),
          AlternativeOption(title: 'Community', description: 'Shared cost'),
        ],
      );
    }
  }
}
