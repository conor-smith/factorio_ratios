part of 'models.dart';

class Recipe extends OrderedWithSubgroup {
  static const double _expectedIconSize = 64,
      _defaultScale = (_expectedIconSize / 2) / _expectedIconSize,
      defaultEnergyRequired = 0.5;

  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  late final ItemSubgroup? subgroup = _determineSubGroup();
  @override
  late final List<IconData>? icons = _icons ?? mainProduct?.icons;
  @override
  double get expectedIconSize => _expectedIconSize;
  @override
  double get defaultScale => _defaultScale;

  final List<String> categories;
  final double energyRequired;
  final double maximumProductivity;
  final double emissionsMultiplier;

  final String? _mainProductString;
  final String? _subgroupString;
  final List<IconData>? _icons;

  final bool enabled;
  final bool allowConsumption;
  final bool allowSpeed;
  final bool allowProductivity;
  final bool allowPollution;
  final bool allowQuality;

  final List<RecipeIngredient> ingredients;
  final List<RecipeProduct> results;
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

  late final List<Surface> surfaces = List.unmodifiable(
    factorioDb.surfaceMap.values.where(
      (surface) => surfaceConditions.every((condition) {
        double? surfaceProperty = surface.surfaceProperties[condition.property];
        if (surfaceProperty == null) {
          return false;
        } else {
          double min = condition.min ?? double.negativeInfinity;
          double max = condition.max ?? double.infinity;
          return surfaceProperty >= min && surfaceProperty <= max;
        }
      }),
    ),
  );

  /// True if this recipe only has one output
  /// and that the inputs of this recipe do not contain the output
  late final bool isSimple =
      results.length == 1 &&
      ingredients.every((ingredient) => ingredient._name != results[0]._name) &&
      !categories.contains('recycling');

  Recipe._({
    required this.factorioDb,
    required this.name,
    required this.order,
    required String? mainProduct,
    required String? subgroup,
    required List<IconData>? icons,
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
       _icons = icons;

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
    late List<RecipeIngredient> ingredients;
    var rawIngredients = json['ingredients'] ?? const [];
    if (rawIngredients is List) {
      ingredients = List.unmodifiable(
        rawIngredients.map(
          (ingredientJson) =>
              RecipeIngredient.fromJson(factorioDb, ingredientJson),
        ),
      );
    } else {
      ingredients = const [];
    }

    late List<RecipeProduct> results;
    var rawResults = json['results'] ?? const [];
    if (rawResults is List) {
      results = List.unmodifiable(
        rawResults.map(
          (resultJson) => RecipeProduct.fromJson(factorioDb, resultJson),
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
      icons: IconData.fromTopLevelJson(json, Recipe._expectedIconSize),
      energyRequired:
          json['energy_required']?.toDouble() ?? defaultEnergyRequired,
      maximumProductivity:
          json['maximum_productivity']?.toDouble() ??
          Effects.productivity.maxMultiplier,
      emissionsMultiplier:
          json['emissions_multiplier']?.toDouble() ??
          Effects.pollution.defaultMultiplier,
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
}

abstract class RecipeItem {
  final FactorioDatabase factorioDb;

  final String _name;
  final String type;

  late final Item item = factorioDb.itemMap[_name]!;

  RecipeItem._({
    required this.factorioDb,
    required String name,
    required this.type,
  }) : _name = name;
}

class RecipeIngredient extends RecipeItem {
  final double? _jsonMinimumTemperature;
  final double? _jsonMaximumTemperature;

  final double amount;
  final double? temperature;
  late final double? minimumTemperature =
      _jsonMinimumTemperature ??
      (type == 'fluid' ? (item as FluidItem).defaultTemperature : null);
  late final double? maximumTemperature =
      _jsonMaximumTemperature ??
      (type == 'fluid' ? (item as FluidItem).defaultTemperature : null);

  RecipeIngredient._({
    required super.factorioDb,
    required super.name,
    required super.type,
    required this.amount,
    required this.temperature,
    required double? minimumTemperature,
    required double? maximumTemperature,
  }) : _jsonMinimumTemperature = minimumTemperature,
       _jsonMaximumTemperature = maximumTemperature,
       super._();

  factory RecipeIngredient.fromJson(FactorioDatabase factorioDb, Map json) =>
      RecipeIngredient._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        amount: json['amount']?.toDouble(),
        temperature: json['temperature']?.toDouble(),
        minimumTemperature: json['maximum_temperature']?.toDouble(),
        maximumTemperature: json['minimum_temperature']?.toDouble(),
      );
}

class RecipeProduct extends RecipeItem {
  final double? amount;
  final double? amountMin;
  final double? amountMax;
  final double probability;
  final double ignoredByProductivity;

  final double extraCountFraction;
  final double percentSpoiled;

  final double? temperature;

  RecipeProduct._({
    required super.factorioDb,
    required super.name,
    required super.type,
    required this.amount,
    required this.amountMin,
    required this.amountMax,
    required this.probability,
    required this.ignoredByProductivity,
    required this.extraCountFraction,
    required this.percentSpoiled,
    required this.temperature,
  }) : super._();

  factory RecipeProduct.fromJson(FactorioDatabase factorioDb, Map json) =>
      RecipeProduct._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        amount: json['amount']?.toDouble(),
        amountMin: json['amount_min']?.toDouble(),
        amountMax: json['amount_max']?.toDouble(),
        probability: json['probability']?.toDouble() ?? 1,
        ignoredByProductivity: json['ignored_by_productivity']?.toDouble() ?? 0,
        extraCountFraction: json['extra_count_fraction']?.toDouble() ?? 0,
        percentSpoiled: json['percent_spoiled']?.toDouble() ?? 0,
        temperature: json['temperature']?.toDouble(),
      );
}

class SurfaceCondition {
  final String property;
  final double? min;
  final double? max;

  SurfaceCondition._({
    required this.property,
    required this.min,
    required this.max,
  });

  factory SurfaceCondition.fromJson(Map json) => SurfaceCondition._(
    property: json['property'],
    min: json['min']?.toDouble(),
    max: json['max']?.toDouble(),
  );
}
