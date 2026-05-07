import 'package:flutter/material.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/models/crop_input_data.dart';
import 'package:smart_crop_assistant/features/crop_recommendation/screens/crop_recommendation_result_screen.dart';

class CropRecommendationStep3Screen extends StatefulWidget {
  final CropInputData inputData;

  const CropRecommendationStep3Screen({super.key, required this.inputData});

  @override
  State<CropRecommendationStep3Screen> createState() =>
      _CropRecommendationStep3ScreenState();
}

class _CropRecommendationStep3ScreenState
    extends State<CropRecommendationStep3Screen> {
  String _selectedBudget = 'Medium';
  String _selectedExperience = 'Intermediate';
  final Set<String> _selectedIrrigation = {'Drip'};
  String _selectedSeason = 'Kharif';

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
          'Farm Resources',
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
                      'Step 3 of 3',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '80% Complete',
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
                    value: 0.8,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about your farm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide details about your resources to help us generate the most accurate crop recommendation.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildBudgetSection(),
            const SizedBox(height: 32),
            _buildExperienceSection(),
            const SizedBox(height: 32),
            _buildIrrigationSection(),
            const SizedBox(height: 32),
            _buildSeasonSection(),
            const SizedBox(height: 100), // spacing for bottom nav
          ],
        ),
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
                  if (_selectedIrrigation.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one irrigation method.')),
                    );
                    return;
                  }

                  final finalData = widget.inputData.copyWith(
                    budget: _selectedBudget,
                    experience: _selectedExperience,
                    irrigation: _selectedIrrigation.toList(),
                    season: _selectedSeason,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CropRecommendationResultScreen(inputData: finalData),
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
                  'Generate',
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

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text(
              'Budget Investment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildBudgetOption('Low')),
            const SizedBox(width: 12),
            Expanded(child: _buildBudgetOption('Medium')),
            const SizedBox(width: 12),
            Expanded(child: _buildBudgetOption('High')),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetOption(String level) {
    final isSelected = _selectedBudget == level;
    return GestureDetector(
      onTap: () => setState(() => _selectedBudget = level),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          level,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceSection() {
    final levels = ['Beginner', 'Intermediate', 'Expert'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text(
              'Farming Experience',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: levels.map((level) {
            final isSelected = _selectedExperience == level;
            return GestureDetector(
              onTap: () => setState(() => _selectedExperience = level),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade700 : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.green.shade700 : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIrrigationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water_drop, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text(
              'Irrigation System',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildIrrigationOption('Rainfed'),
            _buildIrrigationOption('Drip'),
            _buildIrrigationOption('Borewell'),
            _buildIrrigationOption('Canal'),
          ],
        ),
      ],
    );
  }

  Widget _buildIrrigationOption(String type) {
    final isSelected = _selectedIrrigation.contains(type);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIrrigation.remove(type);
          } else {
            _selectedIrrigation.add(type);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text(
              'Crop Season',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildSeasonOption('Monsoon', 'Kharif'),
            _buildSeasonOption('Winter', 'Rabi'),
            _buildSeasonOption('Summer', 'Zaid'),
            _buildSeasonOption('Year Round', 'All Season'),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonOption(String subtitle, String title) {
    final isSelected = _selectedSeason == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedSeason = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subtitle.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green.shade800 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
