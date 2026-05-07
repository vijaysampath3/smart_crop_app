class CropAiGuide {
  final List<GrowingStage> growingStages;
  final List<String> farmingMethods;
  final Fertilizer fertilizer;
  final List<PestPrevention> pestPrevention;
  final MarketDemand marketDemand;
  final List<String> tips;

  CropAiGuide({
    required this.growingStages,
    required this.farmingMethods,
    required this.fertilizer,
    required this.pestPrevention,
    required this.marketDemand,
    required this.tips,
  });

  factory CropAiGuide.fromJson(Map<String, dynamic> json) {
    return CropAiGuide(
      growingStages: (json['growingStages'] as List<dynamic>?)
              ?.map((e) => GrowingStage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      farmingMethods: (json['farmingMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fertilizer: json['fertilizer'] != null
          ? Fertilizer.fromJson(json['fertilizer'] as Map<String, dynamic>)
          : Fertilizer(n: "0", p: "0", k: "0"),
      pestPrevention: (json['pestPrevention'] as List<dynamic>?)
              ?.map((e) => PestPrevention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      marketDemand: json['marketDemand'] != null
          ? MarketDemand.fromJson(json['marketDemand'] as Map<String, dynamic>)
          : MarketDemand(price: "N/A", demandLevel: "N/A", bestSeason: "N/A"),
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class GrowingStage {
  final String title;
  final String subtitle;

  GrowingStage({required this.title, required this.subtitle});

  factory GrowingStage.fromJson(Map<String, dynamic> json) {
    return GrowingStage(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}

class Fertilizer {
  final String n;
  final String p;
  final String k;

  Fertilizer({required this.n, required this.p, required this.k});

  factory Fertilizer.fromJson(Map<String, dynamic> json) {
    return Fertilizer(
      n: json['n']?.toString() ?? '0',
      p: json['p']?.toString() ?? '0',
      k: json['k']?.toString() ?? '0',
    );
  }
}

class PestPrevention {
  final String emoji;
  final String title;
  final String subtitle;

  PestPrevention({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  factory PestPrevention.fromJson(Map<String, dynamic> json) {
    return PestPrevention(
      emoji: json['emoji']?.toString() ?? '⚠️',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}

class MarketDemand {
  final String price;
  final String demandLevel;
  final String bestSeason;

  MarketDemand({
    required this.price,
    required this.demandLevel,
    required this.bestSeason,
  });

  factory MarketDemand.fromJson(Map<String, dynamic> json) {
    return MarketDemand(
      price: json['price']?.toString() ?? 'N/A',
      demandLevel: json['demandLevel']?.toString() ?? 'N/A',
      bestSeason: json['bestSeason']?.toString() ?? 'N/A',
    );
  }
}
