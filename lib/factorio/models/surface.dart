part of '../models.dart';

class Surface extends OrderedWithSubgroup {
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

  final String localisedName;
  final Map<String, double> surfaceProperties;

  final String? _subgroupString;

  late final List<Recipe> recipes = List.unmodifiable(
    factorioDb.recipeMap.values.where(
      (recipe) => recipe.surfaces.contains(this),
    ),
  );

  Surface._({
    required this.factorioDb,
    required this.name,
    required this.localisedName,
    required this.icons,
    required this.order,
    required String? subgroup,
    required this.surfaceProperties,
  }) : _subgroupString = subgroup;

  factory Surface.fromJson(FactorioDatabase factorioDb, Map json) {
    return Surface._(
      factorioDb: factorioDb,
      name: json['name'],
      localisedName: json['name'], // TODO
      icons: IconData.fromTopLevelJson(json, _expectedIconSize),
      order: json['order'],
      subgroup: json['subgroup'],
      surfaceProperties: _parseStringDoubleMap(json['surface_properties']),
    );
  }

  @override
  String toString() => name;
}
