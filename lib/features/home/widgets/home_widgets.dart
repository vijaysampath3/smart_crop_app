import 'package:flutter/material.dart';
import '../../../core/services/weather_service.dart';
import '../../warehouse/warehouse_screen.dart';
import '../../pest_detection/pest_detection_screen.dart';
import '../../market/market_home_screen.dart';
import '../../crop_recommendation/screens/crop_recommendation_step1_screen.dart';
import '../../transport/screens/find_my_transport_screen.dart';
import '../../market/services/auction_service.dart';
import '../../market/models/auction_model.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.menu, color: Colors.green.shade700, size: 30),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Smart Crop',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.language, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'ENG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF16A34A),
            Color(0xFF22C55E),
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Smart Crop Assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Smart tools to help you grow, sell, and manage crops.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CropRecommendationStep1Screen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Get Crop Recommendation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsSection extends StatelessWidget {
  final WeatherService weatherService;
  final bool isLoadingWeather;

  const InsightsSection({
    super.key,
    required this.weatherService,
    required this.isLoadingWeather,
  });

  @override
  Widget build(BuildContext context) {
    IconData weatherIcon = Icons.sensors;
    Color iconColor = Colors.orange.shade400;
    String weatherText = "--°C • Loading...";

    if (!isLoadingWeather && weatherService.hasFetched) {
      weatherIcon = WeatherService.getWeatherIcon(weatherService.weatherCondition);
      weatherText = "${weatherService.currentTemp.round()}°C • ${weatherService.weatherCondition}";
      
      // Dynamic icon color based on condition
      if (weatherIcon == Icons.wb_sunny) {
        iconColor = Colors.orange.shade400;
      } else if (weatherIcon == Icons.cloud || weatherIcon == Icons.wb_cloudy) {
        iconColor = Colors.grey.shade600;
      } else if (weatherIcon == Icons.grain) {
        iconColor = Colors.blue.shade400;
      } else if (weatherIcon == Icons.flash_on) {
        iconColor = Colors.deepPurple.shade400;
      } else if (weatherIcon == Icons.ac_unit) {
        iconColor = Colors.lightBlue.shade300;
      }
    }

    return Transform.translate(
      offset: const Offset(0, -20),
      child: SizedBox(
        height: 120,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            _buildWeatherInsightCard(
              context: context,
              icon: weatherIcon,
              iconColor: iconColor,
              title: 'Weather',
              valueText: weatherText,
            ),
            const SizedBox(width: 12),
            _buildInsightCard(
              context: context,
              icon: Icons.bar_chart,
              iconColor: Colors.blue.shade500,
              title: 'Market Price',
              value: 'Tomato ₹18/kg',
            ),
            const SizedBox(width: 12),
            StreamBuilder<List<AuctionModel>>(
              stream: AuctionService().getActiveAuctions(),
              builder: (context, snapshot) {
                String value = 'Loading...';
                if (snapshot.hasData) {
                  final now = DateTime.now();
                  final activeCount = snapshot.data!.where((a) => now.isBefore(a.endTime)).length;
                  value = '$activeCount running';
                } else if (snapshot.hasError) {
                  value = 'Error';
                }

                return _buildInsightCard(
                  context: context,
                  icon: Icons.gavel,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Active Auctions',
                  value: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInsightCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String valueText,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing $title details...'), duration: const Duration(seconds: 1)));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        valueText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing $title details...'), duration: const Duration(seconds: 1)));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ),
      ),
    );
  }
}

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Farming Services',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: [
              SmartServiceCard(
                icon: Icons.psychology,
                title: 'Crop Recommendation',
                subtitle: 'Personalized soil and climate suggestions.',
                onTapOverride: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CropRecommendationStep1Screen(),
                    ),
                  );
                },
              ),
              SmartServiceCard(
                icon: Icons.storefront,
                title: 'Smart Crop Market',
                subtitle: 'Sell harvest through live auctions.',
                onTapOverride: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarketHomeScreen(),
                    ),
                  );
                },
              ),
              SmartServiceCard(
                icon: Icons.local_shipping,
                title: 'Transport Finder',
                subtitle: 'Find trucks for crop delivery.',
                onTapOverride: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FindMyTransportScreen(),
                    ),
                  );
                },
              ),
              SmartServiceCard(
                icon: Icons.warehouse,
                title: 'Build My Warehouse',
                subtitle: 'Storage planning and construction.',
                onTapOverride: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WarehouseScreen(),
                    ),
                  );
                },
              ),
              SmartServiceCard(
                icon: Icons.bug_report,
                title: 'Pest Detection',
                subtitle: 'Identify and treat crop pests.',
                onTapOverride: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PestDetectionScreen(),
                    ),
                  );
                },
              ),
              SmartServiceCard(
                icon: Icons.update,
                title: 'Coming Soon...',
                subtitle: 'More smart farming tools coming soon',
                iconColor: const Color(0xFF94A3B8),
                titleColor: const Color(0xFF0F172A),
                bgColor: Colors.white,
                iconBgColor: const Color(0xFFF8FAFC),
                opacity: 0.75,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SmartServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final Color? bgColor;
  final Color? iconBgColor;
  final double opacity;
  final VoidCallback? onTapOverride;

  const SmartServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.titleColor,
    this.bgColor,
    this.iconBgColor,
    this.opacity = 1.0,
    this.onTapOverride,
  });

  @override
  State<SmartServiceCard> createState() => _SmartServiceCardState();
}

class _SmartServiceCardState extends State<SmartServiceCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? Colors.green.shade700;
    final titleColor = widget.titleColor ?? Colors.green.shade900;
    final bgColor = widget.bgColor ?? Colors.white;
    final iconBgColor = widget.iconBgColor ?? Colors.green.shade50;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.opacity < 1.0 ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.opacity < 1.0 ? null : (_) {
          setState(() => _isPressed = false);
          if (widget.onTapOverride != null) {
            widget.onTapOverride!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${widget.title}...'), duration: const Duration(seconds: 1)));
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Opacity(
          opacity: widget.opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0)),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered && widget.opacity == 1.0 ? Colors.green.shade200 : const Color(0xFFF1F5F9),
                width: _isHovered && widget.opacity == 1.0 ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered && widget.opacity == 1.0 ? Colors.green.withValues(alpha: 0.15) : Colors.black12,
                  blurRadius: _isHovered && widget.opacity == 1.0 ? 8 : 2,
                  offset: _isHovered && widget.opacity == 1.0 ? const Offset(0, 4) : const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TasksSection extends StatelessWidget {
  const TasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Active Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 16),
          _buildTaskCard(
            context: context,
            label: 'Delivery Pending',
            labelColor: Colors.orange.shade600,
            title: 'Tomato → FreshMart Warehouse',
            borderColor: Colors.orange.shade400,
          ),
          const SizedBox(height: 12),
          _buildTaskCard(
            context: context,
            label: 'Auction Ending Soon',
            labelColor: Colors.green.shade600,
            title: 'Onion Auction • 5 hours left',
            borderColor: Colors.green.shade600,
          ),
          const SizedBox(height: 12),
          _buildTaskCard(
            context: context,
            label: 'Warehouse Plan Ready',
            labelColor: Colors.blue.shade600,
            title: 'View construction steps',
            borderColor: Colors.blue.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required BuildContext context,
    required String label,
    required Color labelColor,
    required String title,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening Task: $title...'), duration: const Duration(seconds: 1)));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
              children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
        ),
        ),
        ),
      ),
    );
  }
}

