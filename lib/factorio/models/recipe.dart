part of 'models.dart';

class Recipe {
  String name;
  String? icon;
  String category;
  double energyRequired;
  double maximumProductivity;
  double emissionsMultiplier;

  bool enabled;
  bool allowConsumption;
  bool allowSpeed;
  bool allowProductivity;
  bool allowPollution;
  bool allowQuality;

  List<RecipeItem> ingredients;
  List<RecipeItem> results;
  List<SurfaceCondition> surfaceConditions;

  Recipe._internal(
    this.name,
    this.icon,
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
    this.surfaceConditions
  );

  factory Recipe.fromJson(Map json) {
    // Empty ingredients are serialised as "{}" in json rather than null or "[]"
    // As such, a factory method is needed
    var rawIngredients = json['ingredients'] ?? const [];
    late List<RecipeItem> ingredients;
    if(rawIngredients is List) {
      ingredients = rawIngredients.map((ingredientJson) => RecipeItem.fromJson(ingredientJson)).toList();
    } else {
      ingredients = const [];
    }

    var rawResults = json['results'] ?? const [];
    late List<RecipeItem> results;
    if(rawResults is List) {
      results = rawResults.map((ingredientJson) => RecipeItem.fromJson(ingredientJson)).toList();
    } else {
      results = const [];
    }

    return Recipe._internal(
      json['name'],
      _getIcon(json),
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
      (json['surface_conditions'] as List? ?? const []).map((surfaceConditionsJson) => SurfaceCondition.fromJson(surfaceConditionsJson)).toList()
    );
  }
}

class RecipeItem {
  String name;
  String type;
  int amount;
  double probability;

  RecipeItem.fromJson(Map json) :
    name = json['name'],
    type = json['type'],
    amount = json['amount'],
    probability = json['probability']?.toDouble() ?? 1;
}

class SurfaceCondition {
  String property;
  double min;
  double max;

  SurfaceCondition.fromJson(Map json) :
    property = json['property'],
    min = json['min']?.toDouble() ?? double.negativeInfinity,
    max = json['max']?.toDouble() ?? double.infinity;
}