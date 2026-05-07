import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/services/weather_service.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/models/crop_input_data.dart';
import 'package:smart_crop_assistant/core/config/app_secrets.dart';
import 'crop_recommendation_step3_screen.dart';

enum SoilInfoMethod { testValues, quickEstimate, healthCard }

class CropRecommendationStep2Screen extends StatefulWidget {
  final CropInputData inputData;

  const CropRecommendationStep2Screen({super.key, required this.inputData});

  @override
  State<CropRecommendationStep2Screen> createState() =>
      _CropRecommendationStep2ScreenState();
}

class _CropRecommendationStep2ScreenState
    extends State<CropRecommendationStep2Screen> {
  SoilInfoMethod _selectedMethod = SoilInfoMethod.testValues;

  // Quick Estimate State
  String? _selectedColor;
  String? _selectedTexture;
  String? _selectedWater;

  // Input Controllers for Nutrient Values (shared by Test Values & Health Card)
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();
  final _cController = TextEditingController();
  final _phController = TextEditingController();

  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _scanHealthCard() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      setState(() {
        _isScanning = true;
      });
      
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      
      const apiKey = AppSecrets.githubCropApiKey;
      final response = await http.post(
        Uri.parse('https://models.inference.ai.azure.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Read the soil health card from the image. 
Extract the values for Nitrogen (N), Phosphorus (P), Potassium (K), Organic Carbon (C), and pH.
Return strictly a JSON object with keys: n, p, k, c, ph containing the numerical values. If a value is missing or cannot be read, put null.''',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'temperature': 0.1,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        var content = data['choices'][0]['message']['content'] as String;
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        
        setState(() {
          if (result['n'] != null) _nController.text = result['n'].toString();
          if (result['p'] != null) _pController.text = result['p'].toString();
          if (result['k'] != null) _kController.text = result['k'].toString();
          if (result['c'] != null) _cController.text = result['c'].toString();
          if (result['ph'] != null) _phController.text = result['ph'].toString();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health card scanned successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to analyze image. Status: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _cController.dispose();
    _phController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Soil Composition',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 2 of 3',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '66% Complete',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.66,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationCard(),
                  const SizedBox(height: 16),
                  _buildMethodSelection(),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildDynamicContent(),
                  ),
                  const SizedBox(height: 100), // spacing for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.shade700, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  CropInputData updatedData = widget.inputData;
                  
                  if (_selectedMethod == SoilInfoMethod.quickEstimate) {
                    if (_selectedColor == null || _selectedTexture == null || _selectedWater == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please answer all quick estimate questions.')),
                      );
                      return;
                    }
                    // Simple mock conversion for quick estimate
                    updatedData = updatedData.copyWith(
                      nLevel: _selectedTexture == 'Clay (Sticky and heavy)' ? 'High' : 'Medium',
                      pLevel: _selectedColor == 'Black' ? 'High' : 'Medium',
                      kLevel: _selectedWater == 'Holds water for a long time' ? 'High' : 'Medium',
                    );
                  } else {
                    // For Test Values or Health Card
                    final n = double.tryParse(_nController.text);
                    final p = double.tryParse(_pController.text);
                    final k = double.tryParse(_kController.text);
                    final c = double.tryParse(_cController.text);
                    final ph = double.tryParse(_phController.text);
                    
                    if (n == null || p == null || k == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid N, P, K values.')),
                      );
                      return;
                    }

                    updatedData = updatedData.copyWith(
                      nitrogen: n,
                      phosphorus: p,
                      potassium: k,
                      organicCarbon: c,
                      ph: ph,
                    );
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CropRecommendationStep3Screen(inputData: updatedData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.green.withValues(alpha: 0.3),
                ),
                child: const Text(
                  'Next Step',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on, color: Colors.green.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT LOCATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.inputData.location.isEmpty ? 'Location not provided' : widget.inputData.location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.green.shade700),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Information Method',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: _buildMethodTab(
                  SoilInfoMethod.testValues,
                  Icons.science,
                  'Soil Values',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: _buildMethodTab(
                  SoilInfoMethod.quickEstimate,
                  Icons.eco,
                  'Quick Estimate',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: _buildMethodTab(
                  SoilInfoMethod.healthCard,
                  Icons.description,
                  'Health Card',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTab(SoilInfoMethod method, IconData icon, String label) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green.shade800 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicContent() {
    switch (_selectedMethod) {
      case SoilInfoMethod.testValues:
        return _buildTestValuesContent();
      case SoilInfoMethod.quickEstimate:
        return _buildQuickEstimateContent();
      case SoilInfoMethod.healthCard:
        return _buildHealthCardContent();
    }
  }

  Widget _buildTestValuesContent() {
    return Column(
      key: const ValueKey('testValues'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrient Composition (mg/kg)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),
        _buildNutrientInput('N', 'Nitrogen', 'e.g. 142', _nController),
        const SizedBox(height: 12),
        _buildNutrientInput('P', 'Phosphorus', 'e.g. 48', _pController),
        const SizedBox(height: 12),
        _buildNutrientInput('K', 'Potassium', 'e.g. 210', _kController),
        const SizedBox(height: 24),
        _buildEnvironmentalIndicators(),
      ],
    );
  }

  Widget _buildNutrientInput(String symbol, String name, String defaultValue, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: defaultValue,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEstimateContent() {
    return Column(
      key: const ValueKey('quickEstimate'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Soil Appearance & Behavior',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Answer simple questions about your soil so we can estimate nutrient levels.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        _buildQuestionSection(
          '1. What is the color of your soil?',
          [
            _buildRadioOption('soilColor', 'Black', _selectedColor, (v) => setState(() => _selectedColor = v)),
            _buildRadioOption('soilColor', 'Red', _selectedColor, (v) => setState(() => _selectedColor = v)),
            _buildRadioOption('soilColor', 'Brown', _selectedColor, (v) => setState(() => _selectedColor = v)),
            _buildRadioOption('soilColor', 'Yellow', _selectedColor, (v) => setState(() => _selectedColor = v)),
          ],
        ),
        const SizedBox(height: 16),
        _buildQuestionSection(
          '2. How does the soil feel in your hand?',
          [
            _buildRadioOption('soilTex', 'Sandy (Loose and dry)', _selectedTexture, (v) => setState(() => _selectedTexture = v)),
            _buildRadioOption('soilTex', 'Clay (Sticky and heavy)', _selectedTexture, (v) => setState(() => _selectedTexture = v)),
            _buildRadioOption('soilTex', 'Loamy (Soft and balanced)', _selectedTexture, (v) => setState(() => _selectedTexture = v)),
          ],
        ),
        const SizedBox(height: 16),
        _buildQuestionSection(
          '3. How long does water stay in your soil?',
          [
            _buildRadioOption('soilWater', 'Drains quickly', _selectedWater, (v) => setState(() => _selectedWater = v)),
            _buildRadioOption('soilWater', 'Stays for some time', _selectedWater, (v) => setState(() => _selectedWater = v)),
            _buildRadioOption('soilWater', 'Holds water for a long time', _selectedWater, (v) => setState(() => _selectedWater = v)),
          ],
        ),
        const SizedBox(height: 24),
        _buildEnvironmentalIndicators(),
      ],
    );
  }

  Widget _buildQuestionSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Column(children: options),
      ],
    );
  }

  Widget _buildRadioOption(String groupName, String title, String? groupValue, ValueChanged<String?> onChanged) {
    final isSelected = groupValue == title;
    return GestureDetector(
      onTap: () => onChanged(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCardContent() {
    return Column(
      key: const ValueKey('healthCard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Soil Health Card Data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the values from your government soil health card.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200, style: BorderStyle.none),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Icon(Icons.photo_camera, size: 32, color: Colors.green.shade700),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan Soil Health Card',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload or capture an image of your card for auto-entry',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanHealthCard,
                icon: _isScanning 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.document_scanner, color: Colors.white),
                label: Text(_isScanning ? 'Scanning...' : 'Scan Soil Card', style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  disabledBackgroundColor: Colors.green.shade400,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildNutrientInput('N', 'Nitrogen (N)', 'e.g. 280', _nController),
        const SizedBox(height: 12),
        _buildNutrientInput('P', 'Phosphorus (P)', 'e.g. 45', _pController),
        const SizedBox(height: 12),
        _buildNutrientInput('K', 'Potassium (K)', 'e.g. 150', _kController),
        const SizedBox(height: 12),
        _buildNutrientInput('C', 'Org. Carbon', 'e.g. 0.65', _cController),
        const SizedBox(height: 12),
        _buildNutrientInput('pH', 'Soil pH Level', 'e.g. 6.5', _phController),
        const SizedBox(height: 24),
        _buildEnvironmentalIndicators(),
      ],
    );
  }

  Widget _buildEnvironmentalIndicators() {
    final weatherService = WeatherService();
    final windStr = weatherService.hasFetched ? '${weatherService.windSpeed.toStringAsFixed(1)} km/h' : '-- km/h';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soil & Climate Health',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: _buildIndicator(Icons.thermostat, 'Temp', '28°C'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _buildIndicator(Icons.water_drop, 'Humidity', '62%'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _buildIndicator(Icons.air, 'Wind Speed', windStr),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
