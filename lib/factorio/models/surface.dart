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
  final List<String> _resources;

  late final List<Recipe> recipes = List.unmodifiable(
    factorioDb.recipeMap.values.where(
      (recipe) => recipe.surfaces.contains(this),
    ),
  );
  late final List<Resource> resources = List.unmodifiable(
    _resources.map((resource) => factorioDb.resourceMap[resource]).nonNulls,
  );
  late final List<Item> resourceItems = List.unmodifiable(
    resources
        .map((resource) => resource.results)
        .expand((results) => results)
        .toSet(),
  );

  Surface._({
    required this.factorioDb,
    required this.name,
    required this.localisedName,
    required this.icons,
    required this.order,
    required String? subgroup,
    required this.surfaceProperties,
    required List<String> resources,
  }) : _subgroupString = subgroup,
       _resources = resources;

  factory Surface.fromJson(FactorioDatabase factorioDb, Map json) {
    List<String> resources = List.unmodifiable(
      json['map_gen_settings']?['autoplace_settings']?['entity']?['settings']
              ?.keys ??
          const [],
    );

    return Surface._(
      factorioDb: factorioDb,
      name: json['name'],
      localisedName: json['name'], // TODO
      icons: IconData.fromTopLevelJson(json, _expectedIconSize),
      order: json['order'],
      subgroup: json['subgroup'],
      surfaceProperties: _parseStringDoubleMap(json['surface_properties']),
      resources: resources,
    );
  }

  @override
  String toString() => name;
}
