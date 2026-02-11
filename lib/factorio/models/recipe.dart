part of '../models.dart';

class Recipe {
  final FactorioDatabase factorioDb;

  final String name;
  final List<String> categories;
  final double energyRequired;
  final double maximumProductivity;
  final double emissionsMultiplier;

  final bool enabled;
  final bool allowConsumption;
  final bool allowSpeed;
  final bool allowProductivity;
  final bool allowPollution;
  final bool allowQuality;

  final List<RecipeItem> ingredients;
  final List<RecipeItem> results;
  final List<SurfaceCondition> surfaceConditions;

  late final List<CraftingMachine> craftingMachines = List.unmodifiable(
    categories.map((category) => factorioDb._craftingCategoryToMachines[category] ?? const [])
    .reduce((cat1List, cat2List) => [...cat1List, ...cat2List])
    .toSet());

  Recipe._({
    required this.factorioDb,
    required this.name,
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
  });

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
          (ingredientJson) => RecipeItem.fromJson(ingredientJson),
        ),
      );
    } else {
      ingredients = const [];
    }

    late List<RecipeItem> results;
    var rawResults = json['results'] ?? const [];
    if (rawResults is List) {
      results = List.unmodifiable(
        rawResults.map((ingredientJson) => RecipeItem.fromJson(ingredientJson)),
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

  @override
  String toString() => name;
}

class RecipeItem {
  final String _name;
  late final Item item;
  final String type;
  final double amount;
  final double probability;

  RecipeItem._({
    required String name,
    required this.type,
    required this.amount,
    required this.probability,
  }) : _name = name;

  factory RecipeItem.fromJson(Map json) => RecipeItem._(
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
