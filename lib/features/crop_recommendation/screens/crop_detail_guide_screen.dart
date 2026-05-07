import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../models/crop_ai_guide.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/models/crop_input_data.dart';
import '../services/crop_ai_service.dart';

class CropDetailGuideScreen extends StatefulWidget {
  final Crop crop;
  final CropInputData inputData;

  const CropDetailGuideScreen({
    super.key,
    required this.crop,
    required this.inputData,
  });

  @override
  State<CropDetailGuideScreen> createState() => _CropDetailGuideScreenState();
}

class _CropDetailGuideScreenState extends State<CropDetailGuideScreen> {
  CropAiGuide? _aiGuide;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAiGuidance();
  }

  Future<void> _fetchAiGuidance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final guide = await CropAiService.fetchCropGuide(
        crop: widget.crop,
        inputData: widget.inputData,
      );
      if (mounted) {
        setState(() {
          _aiGuide = guide;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9), // bg-background-light
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D6A4F), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Crop Detail',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF2D6A4F), size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: Column(
          children: [
            const SizedBox(height: 80), // for AppBar offset
            _buildCropHeader(),
            _buildQuickSummary(),
            _buildWhyThisCrop(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF2D6A4F)),
                      SizedBox(height: 16),
                      Text("Generating tailored AI guidance...", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAiGuidance,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              )
            else if (_aiGuide != null)
              ...[
                _buildGrowingStages(),
                _buildFarmingMethod(),
                _buildFertilizerGuidance(),
                _buildPestPrevention(),
                _buildMarketDemand(),
                _buildTips(),
              ],
          ],
        ),
      ),
      bottomSheet: _buildFooterButtons(),
    );
  }

  Widget _buildCropHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildCropImage(),
                ),
              ),
              if (widget.crop.profitTier == 'High')
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'HIGH YIELD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.crop.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      widget.crop.scientificName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              widget.crop.description,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: _buildSummaryBox(
                icon: Icons.grass,
                label: 'Yield',
                value: widget.crop.yieldEstimate,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: _buildSummaryBox(
                icon: Icons.payments,
                label: 'Profit',
                value: widget.crop.profitTier,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: _buildSummaryBox(
                icon: Icons.schedule,
                label: 'Duration',
                value: '${widget.crop.minDuration}-${widget.crop.maxDuration} D',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFF2D6A4F).withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2D6A4F), size: 24),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D6A4F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyThisCrop() {
    const primaryColor = Color(0xFF2D6A4F);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text(
                'Why This Crop',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildReasonChip('Sandy soil', primaryColor),
              _buildReasonChip('Temp range', primaryColor),
              _buildReasonChip('High demand', primaryColor),
              _buildReasonChip('Moderate water', primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowingStages() {
    const primaryColor = Color(0xFF2D6A4F);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Growing Stages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Positioned(
                left: 19,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  for (var i = 0; i < _aiGuide!.growingStages.length; i++)
                    _buildStageItem(
                      icon: Icons.grass, // Using a generic icon for stages as AI only returns text
                      title: _aiGuide!.growingStages[i].title,
                      subtitle: _aiGuide!.growingStages[i].subtitle,
                      iconBgColor: i == 0 ? primaryColor : (i == 1 ? primaryColor.withValues(alpha: 0.2) : Colors.grey.shade100),
                      iconColor: i == 0 ? Colors.white : (i == 1 ? primaryColor : Colors.grey.shade500),
                      titleColor: i == 0 ? primaryColor : (i == 1 ? Colors.black87 : Colors.grey.shade500),
                      iconBorderColor: i == 1 ? primaryColor.withValues(alpha: 0.5) : null,
                      isLast: i == _aiGuide!.growingStages.length - 1,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required Color titleColor,
    Color? iconBorderColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              border: iconBorderColor != null ? Border.all(color: iconBorderColor, width: 2) : null,
              boxShadow: iconBorderColor == null && iconColor == Colors.white
                  ? [BoxShadow(color: iconBgColor.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingMethod() {
    const primaryColor = Color(0xFF2D6A4F);
    return Container(
      width: double.infinity,
      color: primaryColor.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Methods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _aiGuide!.farmingMethods.map((method) {
              return _buildMethodChip(Icons.eco, method, primaryColor);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(IconData icon, String label, Color color) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 64,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilizerGuidance() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fertilizer (NPK)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Standard requirement per hectare for optimal growth',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: _buildFertilizerBox(_aiGuide!.fertilizer.n, 'Nitrogen (N)', const Color(0xFF2D6A4F)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: _buildFertilizerBox(_aiGuide!.fertilizer.p, 'Phosphorus (P)', Colors.orange.shade400),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: _buildFertilizerBox(_aiGuide!.fertilizer.k, 'Potassium (K)', Colors.blue.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilizerBox(String amount, String nutrient, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'KG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nutrient,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestPrevention() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pest Prevention',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < _aiGuide!.pestPrevention.length; i++) ...[
                  if (i > 0) Divider(color: Colors.grey.shade200, height: 1),
                  _buildPestRow(
                    _aiGuide!.pestPrevention[i].emoji,
                    _aiGuide!.pestPrevention[i].title,
                    _aiGuide!.pestPrevention[i].subtitle,
                    i % 2 == 0 ? Colors.pink.shade50 : Colors.blue.shade50,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestRow(String emoji, String title, String subtitle, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketDemand() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Insight',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMarketInsightItem(
            icon: Icons.bar_chart,
            value: _aiGuide!.marketDemand.price,
            label: 'PRICE',
            iconColor: const Color(0xFF2D6A4F),
            bgColor: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
            borderColor: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
          ),
          const SizedBox(height: 12),
          _buildMarketInsightItem(
            icon: Icons.local_fire_department,
            value: _aiGuide!.marketDemand.demandLevel,
            label: 'DEMAND',
            iconColor: Colors.orange.shade500,
            valueColor: Colors.orange.shade600,
            bgColor: Colors.orange.shade50,
            borderColor: Colors.orange.shade100,
          ),
          const SizedBox(height: 12),
          _buildMarketInsightItem(
            icon: Icons.calendar_today,
            value: _aiGuide!.marketDemand.bestSeason,
            label: 'BEST SEASON',
            iconColor: Colors.blue.shade500,
            valueColor: Colors.blue.shade600,
            bgColor: Colors.blue.shade50,
            borderColor: Colors.blue.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsightItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropImage() {
    if (widget.crop.imageUrl.isEmpty) return _buildImagePlaceholder();
    
    if (widget.crop.imageUrl.startsWith('assets/')) {
      return Image.asset(
        widget.crop.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    return Image.network(
      widget.crop.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Image.asset(
      'assets/images/default_crop.png',
      fit: BoxFit.cover,
    );
  }


  Widget _buildTips() {
    if (_aiGuide!.tips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expert Tips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (var tip in _aiGuide!.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    const primaryColor = Color(0xFF2D6A4F);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: primaryColor.withValues(alpha: 0.2),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bookmark, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Save Crop Plan',
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
              side: const BorderSide(color: primaryColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.download, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  'Download Crop Guide (PDF)',
                  style: TextStyle(
                    color: primaryColor,
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
}
