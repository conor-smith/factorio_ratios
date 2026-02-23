part of '../models.dart';

class Recipe extends OrderedWithSubgroup {
  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  late final ItemSubgroup? subgroup = _determineSubGroup();
  @override
  late final String? icon = _iconString ?? mainProduct?.icon;

  final List<String> categories;
  final double energyRequired;
  final double maximumProductivity;
  final double emissionsMultiplier;

  final String? _mainProductString;
  final String? _subgroupString;
  final String? _iconString;

  final bool enabled;
  final bool allowConsumption;
  final bool allowSpeed;
  final bool allowProductivity;
  final bool allowPollution;
  final bool allowQuality;

  final List<RecipeItem> ingredients;
  final List<RecipeItem> results;
  final List<SurfaceCondition> surfaceConditions;

  late final Item? mainProduct = _determineMainProduct();
  late final String localisedName = _getLocalisedName();

  late final List<CraftingMachine> craftingMachines = List.unmodifiable(
    categories
        .map(
          (category) =>
              factorioDb._craftingCategoryToMachines[category] ?? const [],
        )
        .expand((i) => i)
        .toSet(),
  );

  Recipe._({
    required this.factorioDb,
    required this.name,
    required this.order,
    required String? mainProduct,
    required String? subgroup,
    required String? icon,
    required this.categories,
    required this.energyRequired,
    required this.maximumProductivity,
    required this.emissionsMultiplier,
    required this.enabled,
    required this.allowConsumption,
    required this.allowSpeed,
    required this.allowProductivity,
    required this.allowPollution,
    required this.allowQuality,
    required this.ingredients,
    required this.results,
    required this.surfaceConditions,
  }) : _mainProductString = mainProduct,
       _subgroupString = subgroup,
       _iconString = icon;

  factory Recipe.fromJson(FactorioDatabase factorioDb, Map json) {
    late List<String> categories;
    String? rawCategory = json['category'];
    List<String> rawAdditionalCategories =
        (json['categories'] as List? ?? const []).cast();
    if (rawCategory == null && rawAdditionalCategories.isEmpty) {
      categories = const ['crafting'];
    } else {
      categories = [];
      categories.addAll(rawAdditionalCategories);
      if (rawCategory != null) {
        categories.add(rawCategory);
      }

      categories = List.unmodifiable(categories);
    }

    // Empty ingredients are serialised as "{}" in json rather than null or "[]"
    // As such, a factory method is needed
    late List<RecipeItem> ingredients;
    var rawIngredients = json['ingredients'] ?? const [];
    if (rawIngredients is List) {
      ingredients = List.unmodifiable(
        rawIngredients.map(
          (ingredientJson) => RecipeItem.fromJson(factorioDb, ingredientJson),
        ),
      );
    } else {
      ingredients = const [];
    }

    late List<RecipeItem> results;
    var rawResults = json['results'] ?? const [];
    if (rawResults is List) {
      results = List.unmodifiable(
        rawResults.map(
          (resultJson) => RecipeItem.fromJson(factorioDb, resultJson),
        ),
      );
    } else {
      results = const [];
    }

    List rawSurfaceConditions = json['surface_conditions'] as List? ?? const [];
    List<SurfaceCondition> surfaceConditions = List.unmodifiable(
      rawSurfaceConditions.map(
        (surfaceConditionJson) =>
            SurfaceCondition.fromJson(surfaceConditionJson),
      ),
    );

    return Recipe._(
      factorioDb: factorioDb,
      name: json['name'],
      categories: categories,
      order: json['order'] ?? '',
      mainProduct: json['main_product'],
      subgroup: json['subgroup'],
      icon: json['icon'],
      energyRequired: json['energy_required']?.toDouble() ?? 0.5,
      maximumProductivity: json['maximum_productivity']?.toDouble() ?? 3,
      emissionsMultiplier: json['emissions_multiplier']?.toDouble() ?? 1,
      enabled: json['enabled'] ?? true,
      allowConsumption: json['allow_consumption'] ?? true,
      allowSpeed: json['allow_speed'] ?? true,
      allowProductivity: json['allow_productivity'] ?? false,
      allowPollution: json['allow_pollution'] ?? true,
      allowQuality: json['allow_quality'] ?? true,
      ingredients: ingredients,
      results: results,
      surfaceConditions: surfaceConditions,
    );
  }

  Item? _determineMainProduct() {
    if (_mainProductString != null) {
      return factorioDb.itemMap[_mainProductString];
    } else if (results.length == 1) {
      return results[0].item;
    } else {
      return null;
    }
  }

  ItemSubgroup? _determineSubGroup() {
    if (_subgroupString != null) {
      return factorioDb.itemSubgroupMap[_subgroupString]!;
    } else {
      return mainProduct?.subgroup;
    }
  }

  // TODO - Actually parse locale data
  String _getLocalisedName() {
    return mainProduct?.localisedName ??
        '${name[0].toUpperCase()}${name.substring(1).replaceAll('-', ' ')}';
  }

  @override
  String toString() => name;
}

class RecipeItem {
  final FactorioDatabase factorioDb;

  final String _name;
  final String type;
  final double amount;
  final double probability;

  late final Item item = factorioDb.itemMap[_name]!;

  RecipeItem._({
    required this.factorioDb,
    required String name,
    required this.type,
    required this.amount,
    required this.probability,
  }) : _name = name;

  factory RecipeItem.fromJson(FactorioDatabase factorioDb, Map json) =>
      RecipeItem._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        amount: json['amount'].toDouble(),
        probability: json['probability']?.toDouble() ?? 1,
      );
}

class SurfaceCondition {
  final String property;
  final double min;
  final double max;

  SurfaceCondition._({
    required this.property,
    required this.min,
    required this.max,
  });

  factory SurfaceCondition.fromJson(Map json) => SurfaceCondition._(
    property: json['property'],
    min: json['min']?.toDouble() ?? double.negativeInfinity,
    max: json['max']?.toDouble() ?? double.infinity,
  );
}
