import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smart_crop_assistant/core/config/app_secrets.dart';
import 'pest_detection_detail_screen.dart';

class PestDetectionScreen extends StatefulWidget {
  const PestDetectionScreen({super.key});

  @override
  State<PestDetectionScreen> createState() => _PestDetectionScreenState();
}

class _PestDetectionScreenState extends State<PestDetectionScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _detectionResult;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      
      setState(() {
        _selectedImage = File(image.path);
        _detectionResult = null;
      });
      
      _analyzeImage();
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      
      const apiKey = AppSecrets.githubPestApiKey;
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
                  'text': '''Act as an agricultural expert.

Analyze this crop image and identify pest or disease.

Also provide exactly 3 short quick action tips for farmers.
Each should include:
- title (1-2 words like Humidity, Isolation, Spray, Sunlight)
- value (short instruction)
Keep them practical and easy to understand.

Return STRICT JSON:

{
"name": "",
"scientific_name": "",
"confidence": "",
"treatment": "",
"prevention": "",
"details": "",
"fertilizers": "",
"best_practices": "",
"quick_actions": [
  {
    "title": "",
    "value": ""
  }
]
}

Use simple language for farmers in India.'''
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
        
        // Ensure to parse out json block if markdown formatting is used
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(content);
        
        setState(() {
          _detectionResult = result;
        });
      } else {
        _showError('Failed to analyze image. Error ${response.statusCode}');
      }
    } catch (e) {
      _showError('An error occurred during analysis: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6).withAlpha(200),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pest Detection',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Scan Your Crop',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Point your camera at the affected area of the plant to identify pests and receive instant treatment advice.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildCameraViewport(),
            const SizedBox(height: 32),
            if (_isLoading)
              _buildLoadingState()
            else if (_detectionResult != null)
              _buildDetectionResults()
            else ...[
                const Center(
                  child: Text(
                    'No image selected yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 32),
            ],
            const SizedBox(height: 16),
            _buildQuickTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          CircularProgressIndicator(color: Color(0xFF16A34A)),
          SizedBox(height: 16),
          Text(
            'Analyzing crop image...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Identifying pests and diseases with AI',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewport() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF16A34A).withAlpha(76), // ~0.3 opacity
            width: 2,
            style: BorderStyle.solid,
          ),
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
              : const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCcl26k4lBJSHwfMZKBRuPlryvVLyFAKigIsFau9UzY8vOp3s7Aw3UrUQoMYG9o9Dk1DVAT1yQ7nwdCO0WZNvbtubxgiwlj7X1AWcgjaQ-zAGGgs9_bnKy5Rf15rsz2OhJW_Tfor5LLkzarwPAJ8XEgMQJ65vWjRV9ImvTX4Y716UJ7CHYNr4n1qJ20f1SPlxYuz2exsLRFWkQgmLCmrEJl5s7cudAsDCMb1oKcfyXONLMN5xuEHgZ5S0fHl0ee8ISfZuPv0Fi6Wbs',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color.fromRGBO(255, 255, 255, 0.2),
                    BlendMode.dstATop,
                  ),
                ),
        ),
        child: Stack(
          children: [
            if (_selectedImage == null)
              Center(
                child: SizedBox(
                  width: 192,
                  height: 192,
                  child: CustomPaint(
                    painter: ViewfinderPainter(color: const Color(0xFF16A34A)),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCameraButton(
                    icon: Icons.image,
                    size: 48,
                    bgColor: Colors.white.withAlpha(200),
                    iconColor: const Color(0xFF0F172A), // Make visible for selection
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 24),
                  _buildCameraButton(
                    icon: Icons.camera_alt,
                    size: 64,
                    bgColor: const Color(0xFF16A34A),
                    iconColor: Colors.white,
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 24),
                  _buildCameraButton(
                    icon: Icons.refresh,
                    size: 48,
                    bgColor: Colors.white.withAlpha(200),
                    iconColor: const Color(0xFF0F172A),
                    onPressed: () => _pickImage(ImageSource.camera), // Rerun camera if needed
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraButton({
    required IconData icon,
    required double size,
    required Color bgColor,
    required Color iconColor,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(76)),
        ),
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionResults() {
    final name = _detectionResult!['name'] ?? 'Unknown pest';
    final scientificName = _detectionResult!['scientific_name'] ?? '';
    final confidence = _detectionResult!['confidence'] ?? 'High';
    final treatment = _detectionResult!['treatment'] ?? 'No treatment defined.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detection Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Confidence ($confidence)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          scientificName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.medical_services, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Treatment Advice',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                treatment,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PestDetectionDetailScreen(
                        reportData: _detectionResult!,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Detailed Report',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTips() {
    final List<dynamic> quickActions = _detectionResult?['quick_actions'] ?? [
      { 'title': 'Humidity', 'value': 'Keep below 60%' },
      { 'title': 'Isolation', 'value': 'Isolate plant' },
      { 'title': 'Sanitize', 'value': 'Clean all tools' },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: quickActions.take(3).map((action) {
          final title = action['title']?.toString() ?? 'Action';
          final value = action['value']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildTipCard(
              _getIconForTitle(title),
              title,
              value,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('humid')) return Icons.water_drop;
    if (t.contains('isolat')) return Icons.block;
    if (t.contains('sanit') || t.contains('clean')) return Icons.cleaning_services;
    if (t.contains('sun')) return Icons.light_mode;
    if (t.contains('water')) return Icons.opacity;
    if (t.contains('spray') || t.contains('pest')) return Icons.pest_control;
    return Icons.eco;
  }

  Widget _buildTipCard(IconData icon, String title, String subtitle) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0F172A), size: 24),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class ViewfinderPainter extends CustomPainter {
  final Color color;

  ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const cornerLength = 24.0;
    const cornerRadius = 8.0;

    // Top Left
    var path = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(path, paint);

    // Top Right
    path = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(path, paint);

    // Bottom Right
    path = Path()
      ..moveTo(size.width, size.height - cornerLength)
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(
          size.width, size.height, size.width - cornerRadius, size.height)
      ..lineTo(size.width - cornerLength, size.height);
    canvas.drawPath(path, paint);

    // Bottom Left
    path = Path()
      ..moveTo(cornerLength, size.height)
      ..lineTo(cornerRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
      ..lineTo(0, size.height - cornerLength);
    canvas.drawPath(path, paint);

    // Border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

