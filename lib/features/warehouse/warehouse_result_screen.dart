import 'package:flutter/material.dart';
import 'warehouse_plan_model.dart';
import 'warehouse_pdf_service.dart';

class WarehouseResultScreen extends StatefulWidget {
  final WarehousePlanResult planResult;

  const WarehouseResultScreen({super.key, required this.planResult});

  @override
  State<WarehouseResultScreen> createState() => _WarehouseResultScreenState();
}

class _WarehouseResultScreenState extends State<WarehouseResultScreen> {
  bool _isGeneratingPdf = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF8),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Warehouse Plan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDk3j1LhZ-1OZZy0EcACY9p7t5KX2qJsA4T9RFkeQKnOiZIkB6LyLqTPcEMFIEoFH8uCrC0IfLIk9JE1rDL8VTx6XAmDAYHnmAsd4Iq9czY_9mixLAyaJwSk0JaAIvHbe-Q4hY_WAfJ_v-U9JJrxdZLzDBJ6kQzLd_eN0hnvZ7I8K_oxCRA47WB6Ux-TBxlROmrJZ1kgy7in4vjnP0CeUPE4ZlYGFWUGVBw0r4zDFdV7D863WbRnwb-SzScMj_YaVZzGnkKFrxuABg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'RECOMMENDED TYPE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2E7D32),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.planResult.type,
                                        style: const TextStyle(

                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Optimal',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Best suited for grain and durable crops in your current climate zone.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dimensions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.straighten, color: Color(0xFF2E7D32), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Dimensions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.0,
                  children: [
                    _buildDimensionBox('Length', widget.planResult.dimensions.length, isPrimary: false),
                    _buildDimensionBox('Width', widget.planResult.dimensions.width, isPrimary: false),
                    _buildDimensionBox('Height', widget.planResult.dimensions.height, isPrimary: false),
                    _buildDimensionBox('Total Capacity', widget.planResult.capacity, isPrimary: true),

                  ],
                ),
              ),

              // Estimated Cost
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED BUDGET',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.planResult.budget,
                          style: const TextStyle(

                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.payments,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 40,
                    ),
                  ],
                ),
              ),

              // Construction Steps
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.architecture, color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Construction Steps',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        children: widget.planResult.steps.asMap().entries.map((entry) {
                           int idx = entry.key;
                           String step = entry.value;
                           bool isLast = idx == widget.planResult.steps.length - 1;
                           return Column(

                             children: [
                               _buildStepItem(step, isCompleted: true),
                               if (!isLast) _buildStepSeparator(isCompleted: true),
                             ],
                           );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Storage Tips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.orange.shade800, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Storage Tips',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.planResult.tips.map((tip) => _buildTipItem(tip)),

                    ],
                  ),
                ),
              ),

              // Alternative Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alternative Options',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: widget.planResult.alternatives.map((alt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: _buildAlternativeOption(
                              alt.title,
                              alt.description,
                              _getIconForAlternative(alt.title),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingPdf ? null : () async {
                          setState(() {
                            _isGeneratingPdf = true;
                          });
                          
                          await WarehousePdfService.generateAndSavePdf(widget.planResult, context);
                          
                          if (mounted) {
                            setState(() {
                              _isGeneratingPdf = false;
                            });
                          }
                        },
                        icon: _isGeneratingPdf 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.download, color: Colors.white),
                        label: Text(
                          _isGeneratingPdf ? 'Generating PDF...' : 'Download Plan (PDF)',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to planner
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          backgroundColor: const Color(0xFFE8F5E9),
                          side: const BorderSide(color: Color(0xFFC8E6C9)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Start New Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionBox(String label, String value, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFE8F5E9) : Colors.white,
        border: Border.all(
          color: isPrimary ? const Color(0xFFC8E6C9) : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
              color: isPrimary ? const Color(0xFF2E7D32) : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPrimary ? const Color(0xFF2E7D32) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String text, {required bool isCompleted}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF8FCF8), width: 3),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
              color: isCompleted ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepSeparator({required bool isCompleted}) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 24,
          margin: const EdgeInsets.only(left: 7),
          color: isCompleted ? Colors.grey.shade200 : Colors.grey.shade200,
        ),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeOption(String title, String subtitle, IconData icon) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIconForAlternative(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('cold') || lowerTitle.contains('cool')) return Icons.ac_unit;
    if (lowerTitle.contains('rent') || lowerTitle.contains('lease')) return Icons.key;
    if (lowerTitle.contains('community') || lowerTitle.contains('share') || lowerTitle.contains('group')) return Icons.groups;
    if (lowerTitle.contains('silo') || lowerTitle.contains('metal') || lowerTitle.contains('bin')) return Icons.storage;
    if (lowerTitle.contains('bag') || lowerTitle.contains('sack') || lowerTitle.contains('hermetic')) return Icons.shopping_bag;
    if (lowerTitle.contains('open') || lowerTitle.contains('pad')) return Icons.landscape;
    if (lowerTitle.contains('underground') || lowerTitle.contains('pit')) return Icons.keyboard_double_arrow_down;
    if (lowerTitle.contains('home') || lowerTitle.contains('room')) return Icons.home;
    return Icons.lightbulb_outline;
  }
}
