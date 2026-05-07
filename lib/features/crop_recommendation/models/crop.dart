class Crop {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final String imageUrl;
  final int minDuration;
  final int maxDuration;
  final String yieldEstimate;
  final String profitTier; // "High", "Medium", "Low"
  final String waterRequirement; // "Low", "Moderate", "High"
  
  // Scoring parameters
  final List<String> suitableSoilTypes;
  final List<String> suitableSeasons;
  final double minPh;
  final double maxPh;

  Crop({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.imageUrl,
    required this.minDuration,
    required this.maxDuration,
    required this.yieldEstimate,
    required this.profitTier,
    required this.waterRequirement,
    required this.suitableSoilTypes,
    required this.suitableSeasons,
    required this.minPh,
    required this.maxPh,
  });
}
