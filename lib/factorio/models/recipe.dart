part of 'models.dart';

class Recipe {
  final String name;
  final String category;
  final double energyRequired;
  final double maximumProductivity;
  final double emissionsMultiplier;

  final bool enabled;
  final bool allowConsumption;
  final bool allowSpeed;
  final bool allowProductivity;
  final bool allowPollution;
  final bool allowQuality;

  final Set<RecipeItem> ingredients;
  final Set<RecipeItem> results;
  final Set<SurfaceCondition> surfaceConditions;

  Recipe._internal(
    this.name,
    this.category,
    this.energyRequired,
    this.maximumProductivity,
    this.emissionsMultiplier,
    this.enabled,
    this.allowConsumption,
    this.allowSpeed,
    this.allowProductivity,
    this.allowPollution,
    this.allowQuality,
    this.ingredients,
    this.results,
    this.surfaceConditions,
  );

  factory Recipe.fromJson(Map json) {
    // Empty ingredients are serialised as "{}" in json rather than null or "[]"
    // As such, a factory method is needed
    late Set<RecipeItem> ingredients;
    var rawIngredients = json['ingredients'] ?? const [];
    if (rawIngredients is List) {
      ingredients = Set.unmodifiable(
        rawIngredients.map(
          (ingredientJson) => RecipeItem.fromJson(ingredientJson),
        ),
      );
    } else {
      ingredients = const {};
    }

    late Set<RecipeItem> results;
    var rawResults = json['results'] ?? const [];
    if (rawResults is List) {
      results = Set.unmodifiable(
        rawResults.map((ingredientJson) => RecipeItem.fromJson(ingredientJson)),
      );
    } else {
      results = const {};
    }

    List rawSurfaceConditions = json['surface_conditions'] as List? ?? const [];
    Set<SurfaceCondition> surfaceConditions = Set.unmodifiable(
      rawSurfaceConditions.map(
        (surfaceConditionJson) =>
            SurfaceCondition.fromJson(surfaceConditionJson),
      ),
    );

    return Recipe._internal(
      json['name'],
      json['category'] ?? 'crafting',
      json['energy_required']?.toDouble() ?? 0.5,
      json['maximum_productivity']?.toDouble() ?? 3,
      json['emissions_multiplier']?.toDouble() ?? 1,
      json['enabled'] ?? true,
      json['allow_consumption'] ?? true,
      json['allow_speed'] ?? true,
      json['allow_productivity'] ?? false,
      json['allow_pollution'] ?? true,
      json['allow_quality'] ?? true,
      ingredients,
      results,
      surfaceConditions,
    );
  }
}

class RecipeItem {
  final String name;
  final String type;
  final int amount;
  final double probability;

  RecipeItem.fromJson(Map json)
    : name = json['name'],
      type = json['type'],
      amount = json['amount'],
      probability = json['probability']?.toDouble() ?? 1;
}

class SurfaceCondition {
  final String property;
  final double min;
  final double max;

  SurfaceCondition.fromJson(Map json)
    : property = json['property'],
      min = json['min']?.toDouble() ?? double.negativeInfinity,
      max = json['max']?.toDouble() ?? double.infinity;
}
