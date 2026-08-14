part of 'models.dart';

class Quality extends PrototypeWithIcon {
  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String type;
  @override
  final String localisedName;
  @override
  final String order;
  @override
  final Icon? icon;

  String? _subgroupString;
  @override
  late final ItemSubgroup? subgroup =
      factorioDb.itemSubgroupMap[_subgroupString];

  final bool drawSpriteByDefault;
  final int level;

  final String? _nextQualityString;
  final String? _previousQualityString;
  late final Quality? next = factorioDb.qualityMap[_nextQualityString];
  late final Quality? previous = factorioDb.qualityMap[_previousQualityString];

  final double nextProbability;
  final double chainProbability;
  final double previousProbability;
  final double previousChainProbability;

  Quality._({
    required this.factorioDb,
    required this.name,
    required this.type,
    required this.localisedName,
    required this.order,
    required this.icon,
    required String subgroup,
    required this.drawSpriteByDefault,
    required this.level,
    required String nextQuality,
    required String previousQuality,
    required this.nextProbability,
    required this.chainProbability,
    required this.previousProbability,
    required this.previousChainProbability,
  }) : _subgroupString = subgroup,
       _nextQualityString = nextQuality,
       _previousQualityString = previousQuality;

  factory Quality.fromJson(FactorioDatabase factorioDb, Map json) {
    double nextProbability = json['next_probability']?.toDouble() ?? 0;
    double chainProbability =
        json['chain_probability']?.toDouble() ??
        (nextProbability * 0.1).clamp(0, 1);
    double previousProbability = json['previous_probability']?.toDouble() ?? 0;
    double previousChainProbability =
        json['previous_chain_probability']?.toDouble() ??
        (previousProbability * 0.1).clamp(0, 1);

    return Quality._(
      factorioDb: factorioDb,
      name: json['name'],
      type: json['type'],
      localisedName: json['name'],
      order: json['order'],
      icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
      subgroup: json['subgroup'],
      drawSpriteByDefault: json['draw_sprite_by_default'] ?? true,
      level: json['level'],
      nextQuality: json['next'],
      previousQuality: json['previous'],
      nextProbability: nextProbability,
      chainProbability: chainProbability,
      previousProbability: previousProbability,
      previousChainProbability: previousChainProbability,
    );
  }
}
