import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/weather_service.dart';

import 'package:smart_crop_assistant/core/config/app_secrets.dart';

// Loaded from app_secrets.dart
const String openAiApiKey = AppSecrets.githubApiKey;
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService weatherService = WeatherService();

  bool isLoading = true;
  String errorMessage = '';

  // Weather Data getters mapped to WeatherService
  String get locationName => weatherService.locationName;
  double get currentTemp => weatherService.currentTemp;
  double get minTemp => weatherService.minTemp;
  double get maxTemp => weatherService.maxTemp;
  String get weatherCondition => weatherService.weatherCondition;
  int get humidity => weatherService.humidity;
  double get windSpeed => weatherService.windSpeed;
  double get uvIndex => weatherService.uvIndex;
  List<double> get dailyRainfall => weatherService.dailyRainfall;
  List<String> get dailyLabels => weatherService.dailyLabels;

  // Alerts
  List<Map<String, dynamic>> agriculturalAlerts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // 1. Get Location
      Position position = await _determinePosition();
      
      // 2. Fetch Weather
      await weatherService.fetchWeather(position.latitude, position.longitude);

      // 3. Fetch AI Alerts
      await _fetchAlerts();

    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load weather data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  List<Map<String, dynamic>> _generateRuleBasedAlerts() {
    List<Map<String, dynamic>> rules = [];
    if (humidity > 70) {
      rules.add({
        "title": "High Fungal Risk",
        "type": "warning",
        "message": "Humidity is above 70%. High risk of fungal diseases. Consider applying preventive fungicides."
      });
    }
    if (windSpeed > 20) {
      rules.add({
        "title": "Avoid Spraying",
        "type": "warning",
        "message": "Wind speed exceeds 20 km/h. Avoid pesticide spraying to prevent excessive drift."
      });
    }
    if (uvIndex > 7) {
      rules.add({
        "title": "High UV Exposure",
        "type": "warning",
        "message": "High UV Index. Ensure adequate sun protection for field workers."
      });
    }
    if (dailyRainfall.any((r) => r > 0)) {
      rules.add({
        "title": "Rain Expected",
        "type": "info",
        "message": "Rain is expected in the upcoming days. Adjust your irrigation schedule accordingly."
      });
    }
    return rules;
  }

  Future<void> _fetchAlerts() async {
    final ruleAlerts = _generateRuleBasedAlerts();
    final rainSummary = dailyRainfall.where((r) => r > 0).isNotEmpty ? "Some rain expected in the next 7 days." : "No rain expected.";
    final prompt = """
Act as an agricultural expert.

Based on the following weather conditions:
Temperature: $currentTemp°C
Humidity: $humidity%
Wind Speed: ${windSpeed.toStringAsFixed(1)} km/h
Rain forecast: $rainSummary
UV Index: $uvIndex

Generate agricultural alerts for farmers.

Return STRICT JSON:

{
"alerts": [
{
"title": "",
"type": "info/warning/success",
"message": ""
}
]
}

Generate 2–3 alerts such as:
* Pest risk
* Irrigation advice
* Spray warnings (based on wind speed)
* Weather risks

Keep it simple and practical for farmers in India.
""";

    try {
      final response = await http.post(
        Uri.parse('https://models.inference.ai.azure.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        // Remove markdown formatting if any
        final cleanContent = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final jsonResult = jsonDecode(cleanContent);
        
        setState(() {
          agriculturalAlerts = [...ruleAlerts, ...List<Map<String, dynamic>>.from(jsonResult['alerts'])];
        });
      } else {
        throw Exception('OpenAI Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to get AI Alerts: $e');
      setState(() {
        agriculturalAlerts = [
          ...ruleAlerts,
          {
            "title": "Pest Outbreak Risk: Moderate",
            "type": "warning",
            "message": "Warm and humid conditions favor Aphid reproduction. Increase crop monitoring."
          },
          {
            "title": "Irrigation Suggestion",
            "type": "success",
            "message": "Soil moisture likely high due to recent/expected rain. Hold off heavy irrigation."
          }
        ];
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('clear') || lower.contains('sun')) return Icons.wb_sunny;
    if (lower.contains('cloud')) return Icons.cloud;
    if (lower.contains('rain') || lower.contains('drizzle')) return Icons.grain;
    if (lower.contains('thunderstorm') || lower.contains('storm')) return Icons.flash_on;
    if (lower.contains('snow')) return Icons.ac_unit;
    return Icons.cloud;
  }



  // Smart Labels Helpers
  String _getWindLabel(double speed) {
    if (speed < 10) return "Good for spraying";
    if (speed <= 20) return "Moderate wind";
    return "Avoid spraying";
  }

  Color _getWindColor(double speed) {
    if (speed < 10) return Colors.green;
    if (speed <= 20) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getWindIcon(double speed) {
    if (speed < 10) return Icons.check_circle_outline;
    if (speed <= 20) return Icons.warning_amber_rounded;
    return Icons.cancel_outlined;
  }

  String _getUVLabel(double uv) {
    if (uv > 7) return "High exposure warning";
    return "Moderate exposure";
  }

  Color _getUVColor(double uv) {
    if (uv > 7) return Colors.red;
    return Colors.orange;
  }

  String _getHumidityLabel(int hum) {
    if (hum > 70) return "Risk of fungal disease";
    return "Optimal level";
  }

  Color _getHumidityColor(int hum) {
    if (hum > 70) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WeatherHeader(),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : RefreshIndicator(
                  color: Colors.green,
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(errorMessage, style: TextStyle(color: Colors.red.shade700)),
                            ),
                          _buildWeatherCard(),
                          const SizedBox(height: 24),
                          const Text('Current Conditions',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          _buildCurrentConditionsLayout(),
                          const SizedBox(height: 24),
                          const Text('Rainfall Forecast',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          _buildRainfallForecastGraph(),
                          const SizedBox(height: 24),
                          const Text('Agricultural Alerts',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          _buildAgriculturalAlerts(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade500.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentTemp.round()}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weatherCondition.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.thermostat, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('H: ${maxTemp.round()}°', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.thermostat, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('L: ${minTemp.round()}°', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _getWeatherIcon(weatherCondition),
                color: Colors.white,
                size: 80,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConditionsLayout() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              child: _buildInfoCard('Humidity', '$humidity%', Icons.water_drop_outlined, _getHumidityLabel(humidity), _getHumidityColor(humidity), Icons.info_outline),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: _buildInfoCard('Wind Speed', '${windSpeed.toStringAsFixed(1)} km/h', Icons.air, _getWindLabel(windSpeed), _getWindColor(windSpeed), _getWindIcon(windSpeed)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: _buildInfoCard('UV Index', uvIndex.toString(), Icons.wb_sunny_outlined, _getUVLabel(uvIndex), _getUVColor(uvIndex), Icons.warning_amber_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData titleIcon, String subtitle, Color subtitleColor, IconData? subtitleIcon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Icon(titleIcon, color: Colors.green.shade600, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (subtitleIcon != null) ...[
                Icon(subtitleIcon, color: subtitleColor, size: 14),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRainfallForecastGraph() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 200,
            child: BarChart(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (dailyRainfall.isEmpty
                        ? 10
                        : dailyRainfall.reduce((a, b) => a > b ? a : b)) +
                    5,

                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.green,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} mm',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),

                titlesData: FlTitlesData(
                  show: true,

                  // ✅ BOTTOM TITLES (DAYS)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dailyLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dailyLabels[value.toInt()],
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // ✅ LEFT TITLES (NUMBERS ONLY)
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        if (value % 10 != 0) return const SizedBox();

                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),

                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),

                borderData: FlBorderData(show: false),

                barGroups: List.generate(
                  7,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dailyRainfall[index],
                        color: const Color(0xFF16A34A),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: const Text(
            '7-Day Rainfall Forecast (mm)',
            style: TextStyle(color: Color(0xFF475569), fontSize: 14),
          ),
        )
      ],
    ),
  );
}

  Widget _buildAgriculturalAlerts() {
    if (agriculturalAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('No active alerts at the moment.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: agriculturalAlerts.map((alert) {
        final type = alert['type']?.toString().toLowerCase() ?? 'info';
        
        Color iconColor;
        Color iconBgColor;
        Color bgColor;
        Color borderColor;
        IconData icon;
        Color statusColor;
        Color statusBgColor;

        if (type == 'warning') {
          iconColor = Colors.red.shade600;
          iconBgColor = Colors.red.shade100;
          bgColor = Colors.red.shade50;
          borderColor = Colors.red.shade200;
          icon = Icons.warning_rounded;
          statusColor = Colors.red.shade800;
          statusBgColor = Colors.red.shade200;
        } else if (type == 'success') {
          iconColor = Colors.green.shade600;
          iconBgColor = Colors.green.shade100;
          bgColor = Colors.green.shade50;
          borderColor = Colors.green.shade200;
          icon = Icons.check_circle_outline;
          statusColor = Colors.green.shade800;
          statusBgColor = Colors.green.shade200;
        } else {
          // info
          iconColor = Colors.blue.shade600;
          iconBgColor = Colors.blue.shade100;
          bgColor = Colors.blue.shade50;
          borderColor = Colors.blue.shade200;
          icon = Icons.info_outline;
          statusColor = Colors.blue.shade800;
          statusBgColor = Colors.blue.shade200;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildAlertCard(
            icon: icon,
            iconBgColor: iconBgColor,
            iconColor: iconColor,
            bgColor: bgColor,
            borderColor: borderColor,
            title: alert['title'] ?? 'Alert',
            status: type.toUpperCase(),
            statusBgColor: statusBgColor,
            statusColor: statusColor,
            description: alert['message'] ?? '',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String status,
    required Color statusBgColor,
    required Color statusColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
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

class WeatherHeader extends StatelessWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 48, // 48 is horizontal padding (24 * 2)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.menu, color: Colors.green.shade600, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Weather Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24), // Minimum spacing between title and icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Colors.black54, size: 20),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none, color: Colors.black54, size: 20),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
