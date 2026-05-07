import 'package:flutter/material.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/models/crop_input_data.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/screens/crop_detail_guide_screen.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/models/crop.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/services/crop_recommendation_service.dart';

class CropRecommendationResultScreen extends StatefulWidget {
  final CropInputData inputData;

  const CropRecommendationResultScreen({super.key, required this.inputData});

  @override
  State<CropRecommendationResultScreen> createState() => _CropRecommendationResultScreenState();
}

class _CropRecommendationResultScreenState extends State<CropRecommendationResultScreen> {
  late Future<List<Map<String, dynamic>>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = CropRecommendationEngine.getRecommendations(widget.inputData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Crop Recommendations',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSummarySection(),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _recommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return _buildRecommendationsSection(context, snapshot.data!);
                }
                return const SizedBox.shrink();
              },
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Farmer Input Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Edit Inputs',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryChip(Icons.location_on, widget.inputData.location.isNotEmpty ? widget.inputData.location : 'Not provided'),
              _buildSummaryChip(Icons.filter_hdr, widget.inputData.soilType),
              _buildSummaryChip(Icons.water_drop, widget.inputData.irrigation.isNotEmpty ? widget.inputData.irrigation.join(', ') : 'Unknown'),
              if (widget.inputData.ph != null) _buildSummaryChip(Icons.science, 'pH: ${widget.inputData.ph}'),
              _buildSummaryChip(Icons.calendar_today, widget.inputData.season),
              _buildSummaryChip(Icons.payments, widget.inputData.budget),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF22C55E)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, List<Map<String, dynamic>> topRecommendations) {
    if (topRecommendations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'No crops matched your inputs. Try adjusting them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Recommended Crops',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...topRecommendations.map((recommendation) {
            String name = recommendation['name'];
            String confidence = recommendation['confidence'];
            List<String> rawTags = List<String>.from(recommendation['tags']);
            
            List<Widget> tags = rawTags.map((tag) {
              Color tagColor = Colors.green;
              if (tag.contains("High Profit")) tagColor = Colors.purple;
              if (tag.contains("Water")) tagColor = Colors.blue;
              return _buildTag(tag, tagColor);
            }).toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildCropCard(
                context: context,
                recommendation: recommendation,
                title: name,
                imageUrl: recommendation['imageUrl']?.toString() ?? "",
                matchPercentage: confidence,
                tags: tags,
                waterRequirement: rawTags.any((t) => t.contains("Water")) ? rawTags.firstWhere((t) => t.contains("Water")) : "Unknown",
                estimatedYield: "Standard",
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCropCard({
    required BuildContext context,
    required Map<String, dynamic> recommendation,
    required String title,
    required String imageUrl,
    required String matchPercentage,
    required List<Widget> tags,
    required String waterRequirement,
    required String estimatedYield,
  }) {
    return GestureDetector(
      onTap: () {
        // Fallback crop object if detailed screen requires one
        final fallbackCrop = Crop(
          id: title.toLowerCase().replaceAll(' ', '-'),
          name: title,
          scientificName: title,
          description: "Recommended crop based on analysis.",
          imageUrl: imageUrl,
          minDuration: 90,
          maxDuration: 120,
          yieldEstimate: estimatedYield,
          profitTier: recommendation['tags'].contains("High Profit") ? "High" : "Medium",
          waterRequirement: waterRequirement,
          suitableSoilTypes: [widget.inputData.soilType],
          suitableSeasons: [widget.inputData.season],
          minPh: 6.0,
          maxPh: 7.0,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropDetailGuideScreen(crop: fallbackCrop, inputData: widget.inputData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('assets/')
                          ? Image.asset(
                              imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildListPlaceholder(),
                            )
                          : Image.network(
                              imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildListPlaceholder(),
                            ))
                      : _buildListPlaceholder(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: tags,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      matchPercentage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const Text(
                      'MATCH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 64 - 12) / 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water_drop, size: 14, color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WATER REQ.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              waterRequirement,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 64 - 12) / 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.trending_up, size: 14, color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EST. YIELD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              estimatedYield,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF22C55E).withValues(alpha: 0.4),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.restart_alt, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Get New Recommendation',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.download, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  'Download PDF Report',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/images/default_crop.png',
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      ),
    );
  }
}
