part of 'models.dart';

class Recipe {
  final FactorioDatabase _factorioDb;

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

  late final List<CraftingMachine> craftingMachines = _getCraftingMachines();

  Recipe._internal(
    this._factorioDb,
    this.name,
    this.categories,
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

    return Recipe._internal(
      factorioDb,
      json['name'],
      categories,
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

  List<CraftingMachine> _getCraftingMachines() {
    Set<CraftingMachine> machines = {};
    for (var category in categories) {
      machines.addAll(
        _factorioDb._craftingCategoriesAndMachines[category] ?? const [],
      );
    }

    return List.unmodifiable(
      machines.toList()..sort(
        (machine1, machine2) =>
            machine1.craftingSpeed.compareTo(machine2.craftingSpeed),
      ),
    );
  }
}

class RecipeItem {
  final String _name;
  late final Item item;
  final String type;
  final double amount;
  final double probability;

  RecipeItem.fromJson(Map json)
    : _name = json['name'],
      type = json['type'],
      amount = json['amount'].toDouble(),
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
