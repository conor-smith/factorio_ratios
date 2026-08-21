part of 'models.dart';

class Quality extends PrototypeWithIcon {
  static const String defaultName = 'normal';

  @override
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
  late final List<Quality> nextQualityChain = next == null
      ? const []
      : List.unmodifiable([next!, ...next!.nextQualityChain]);
  late final List<Quality> previousQualityChain = previous == null
      ? const []
      : List.unmodifiable([previous!, ...previous!.previousQualityChain]);
  Quality get finalQualityInChain => nextQualityChain.lastOrNull ?? this;
  Quality get firstQualityInChain => previousQualityChain.firstOrNull ?? this;

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

  /// Returns [QualityChainComparison.equal] if [other] is equal,
  /// [QualityChainComparison.greater] if [other] exists in [nextQualityChain],
  /// [QualityChainComparison.lesser] if [other] exists in [previousQualityChain],
  /// and [QualityChainComparison.notInChain] if [other] is not in chain at all.
  QualityChainComparison chainCompare(Quality other) {
    if (this == other) {
      return QualityChainComparison.equal;
    } else if (nextQualityChain.contains(other)) {
      return QualityChainComparison.greater;
    } else if (previousQualityChain.contains(other)) {
      return QualityChainComparison.lesser;
    } else {
      return QualityChainComparison.notInChain;
    }
  }

  Quality? operator +(int toAdd) => _qualitySum(toAdd);

  Quality? operator -(int toSubtract) => _qualitySum(-toSubtract);

  Quality? _qualitySum(int toAdd) {
    if (toAdd == 0) {
      return this;
    }

    List<Quality> chainToScan = toAdd > 0
        ? nextQualityChain
        : previousQualityChain;

    toAdd = toAdd.abs();

    if (toAdd > chainToScan.length) {
      return null;
    } else {
      return chainToScan[toAdd];
    }
  }
}

enum QualityChainComparison {
  equal(true, true),
  greater(false, true),
  lesser(true, false),
  notInChain(false, false);

  final bool lessThanOrEqual;
  final bool greaterThanOrEqual;

  const QualityChainComparison(this.lessThanOrEqual, this.greaterThanOrEqual);
}
