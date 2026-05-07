class CropInputData {
  // Step 1
  final String location;
  final String soilType;
  final double farmSize;

  // Step 2 directly or from Health Card
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? ph;
  final double? organicCarbon;
  final double? temperature;

  // Step 2 from Quick Estimate
  final String? nLevel; // Low/Medium/High
  final String? pLevel;
  final String? kLevel;

  // Step 3
  final List<String> irrigation;
  final String budget;
  final String experience;
  final String season;

  CropInputData({
    this.location = '',
    this.soilType = '',
    this.farmSize = 0.0,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.ph,
    this.organicCarbon,
    this.temperature,
    this.nLevel,
    this.pLevel,
    this.kLevel,
    this.irrigation = const [],
    this.budget = '',
    this.experience = '',
    this.season = '',
  });

  CropInputData copyWith({
    String? location,
    String? soilType,
    double? farmSize,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? ph,
    double? organicCarbon,
    double? temperature,
    String? nLevel,
    String? pLevel,
    String? kLevel,
    List<String>? irrigation,
    String? budget,
    String? experience,
    String? season,
  }) {
    return CropInputData(
      location: location ?? this.location,
      soilType: soilType ?? this.soilType,
      farmSize: farmSize ?? this.farmSize,
      nitrogen: nitrogen ?? this.nitrogen,
      phosphorus: phosphorus ?? this.phosphorus,
      potassium: potassium ?? this.potassium,
      ph: ph ?? this.ph,
      organicCarbon: organicCarbon ?? this.organicCarbon,
      temperature: temperature ?? this.temperature,
      nLevel: nLevel ?? this.nLevel,
      pLevel: pLevel ?? this.pLevel,
      kLevel: kLevel ?? this.kLevel,
      irrigation: irrigation ?? this.irrigation,
      budget: budget ?? this.budget,
      experience: experience ?? this.experience,
      season: season ?? this.season,
    );
  }

  // Normalized getters
  String get normalizedSoilType => soilType.toLowerCase();
  String get normalizedSeason => season.toLowerCase();
  String get normalizedBudget => budget.toLowerCase();
  String get normalizedExperience => experience.toLowerCase();
  List<String> get normalizedIrrigation =>
      irrigation.map((e) => e.toLowerCase()).toList();
}
