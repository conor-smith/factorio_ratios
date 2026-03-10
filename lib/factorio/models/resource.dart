part of '../models.dart';

class Resource extends OrderedWithSubgroup {
  static const double _expectedIconSize = 64;
  static const double _defaultScale =
      (_expectedIconSize / 2) / _expectedIconSize;

  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  late final ItemSubgroup? subgroup =
      factorioDb.itemSubgroupMap[_subgroupString];

  @override
  final List<IconData>? icons;
  @override
  double get expectedIconSize => _expectedIconSize;
  @override
  double get defaultScale => _defaultScale;

  final String? _subgroupString;
  final List<String> _resultsString;

  late final List<Item> results = List.unmodifiable(
    _resultsString.map((itemName) => factorioDb.itemMap[itemName]!),
  );
  late final List<Surface> surfaces = List.unmodifiable(
    factorioDb.surfaceMap.values.where(
      (surface) => surface.resources.contains(this),
    ),
  );

  Resource._({
    required this.factorioDb,
    required this.name,
    required this.order,
    required String? subgroup,
    required this.icons,
    required List<String> resultsString,
  }) : _subgroupString = subgroup,
       _resultsString = resultsString;

  factory Resource.fromJson(FactorioDatabase factorioDb, Map json) {
    List<String> resultsString;
    if (json['minable'] == null) {
      resultsString = const [];
    } else if (json['minable']['results'] != null) {
      List<Map> resultsJson = (json['minable']['results'] as List).cast();

      resultsString = List.unmodifiable(
        resultsJson.map((resultJson) => resultJson['name'] as String),
      );
    } else {
      resultsString = List.unmodifiable([json['minable']['result']]);
    }

    return Resource._(
      factorioDb: factorioDb,
      name: json['name'],
      subgroup: json['subgroup'],
      order: json['order'] ?? '',
      icons: IconData.fromTopLevelJson(json, Item._expectedIconSize),
      resultsString: resultsString,
    );
  }
}

class Mineable {}
