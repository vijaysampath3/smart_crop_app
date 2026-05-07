class WarehousePlanInfo {
  final String location;
  final String capacity;
  final String method;
  final String budget;
  final String crop;

  WarehousePlanInfo({
    required this.location,
    required this.capacity,
    required this.method,
    required this.budget,
    required this.crop,
  });
}

class DimensionModel {
  final String length;
  final String width;
  final String height;

  DimensionModel({
    required this.length,
    required this.width,
    required this.height,
  });

  factory DimensionModel.fromJson(Map<String, dynamic> json) {
    return DimensionModel(
      length: json['length']?.toString() ?? '',
      width: json['width']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
    );
  }
}

class AlternativeOption {
  final String title;
  final String description;

  AlternativeOption({required this.title, required this.description});

  factory AlternativeOption.fromJson(Map<String, dynamic> json) {
    return AlternativeOption(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class WarehousePlanResult {
  final String type;
  final DimensionModel dimensions;
  final String capacity;
  final String budget;
  final List<String> steps;
  final List<String> tips;
  final List<AlternativeOption> alternatives;

  WarehousePlanResult({
    required this.type,
    required this.dimensions,
    required this.capacity,
    required this.budget,
    required this.steps,
    required this.tips,
    required this.alternatives,
  });

  factory WarehousePlanResult.fromJson(Map<String, dynamic> json) {
    return WarehousePlanResult(
      type: json['type']?.toString() ?? '',
      dimensions: DimensionModel.fromJson(json['dimensions'] ?? {}),
      capacity: json['capacity']?.toString() ?? '',
      budget: json['budget']?.toString() ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => AlternativeOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
