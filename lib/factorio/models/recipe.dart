part of 'models.dart';

class Recipe extends PrototypeWithIcon {
  static const double defaultEnergyRequired = 0.5;

  @override
  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  final String type;
  @override
  late final ItemSubgroup? subgroup = _determineSubGroup();
  @override
  late final Icon? icon = _icon ?? mainProduct?.icon;
  @override
  late final String localisedName = _getLocalisedName();

  final List<String> categories;
  final double energyRequired;
  final double maximumProductivity;
  final double emissionsMultiplier;

  final String? _mainProductString;
  final String? _subgroupString;
  final Icon? _icon;

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

  /// Crafting machines sorted by speed in descending order
  late final List<CraftingMachine> sortedCraftingMachines = List.unmodifiable(
    categories
        .expand<CraftingMachine>(
          (category) =>
              factorioDb._craftingCategoryToMachines[category] ?? const [],
        )
        .toSet() // Removes duplicates
        .toList(growable: false)
      ..sort((machine1, machine2) {
        var speedCompare = machine2.craftingSpeed.compareTo(
          machine1.craftingSpeed,
        );
        if (speedCompare != 0) {
          return speedCompare;
        } else {
          var electricMachine1 =
              machine1.energySource.type == EnergySourceType.electric ? 1 : 0;
          var electricMachine2 =
              machine2.energySource.type == EnergySourceType.electric ? 1 : 0;
          return electricMachine2 - electricMachine1;
        }
      }),
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
    required this.type,
    required this.order,
    required String? mainProduct,
    required String? subgroup,
    required Icon? icon,
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
       _icon = icon;

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
      type: json['type'],
      categories: categories,
      order: json['order'] ?? '',
      mainProduct: json['main_product'],
      subgroup: json['subgroup'],
      icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
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

class RecipeIngredient {
  final FactorioDatabase factorioDb;

  final String _name;
  final String type;

  late final Item item = factorioDb.itemMap[_name]!;

  final double? _givenMinimumTemperature;
  final double? _givenMaximumTemperature;

  final double amount;

  final String? _qualityMinString;
  final String? _qualityMaxString;
  late final Quality? qualityMin = factorioDb.qualityMap[_qualityMinString];
  late final Quality? qualityMax = factorioDb.qualityMap[_qualityMaxString];

  final int? qualityChange;

  final double? spoilWeight;

  final double? temperature;
  late final double? minimumTemperature =
      _givenMinimumTemperature ??
      (type == 'fluid' ? (item as FluidItem).defaultTemperature : null);
  late final double? maximumTemperature =
      _givenMaximumTemperature ??
      (type == 'fluid' ? (item as FluidItem).defaultTemperature : null);

  RecipeIngredient._item({
    required this.factorioDb,
    required String name,
    required this.amount,
    required String? qualityMin,
    required String? qualityMax,
    required int this.qualityChange,
    required double this.spoilWeight,
  }) : _name = name,
       type = 'item',
       _qualityMinString = qualityMin,
       _qualityMaxString = qualityMax,
       temperature = null,
       _givenMinimumTemperature = null,
       _givenMaximumTemperature = null;

  RecipeIngredient._fluid({
    required this.factorioDb,
    required String name,
    required this.amount,
    required this.temperature,
    required double? minimumTemperature,
    required double? maximumTemperature,
  }) : _name = name,
       type = 'fluid',
       _givenMinimumTemperature = minimumTemperature,
       _givenMaximumTemperature = maximumTemperature,
       _qualityMinString = null,
       _qualityMaxString = null,
       qualityChange = null,
       spoilWeight = null;

  factory RecipeIngredient.fromJson(FactorioDatabase factorioDb, Map json) =>
      switch (json['type']) {
        'item' => RecipeIngredient._item(
          factorioDb: factorioDb,
          name: json['name'],
          amount: json['amount']?.toDouble(),
          qualityMin: json['quality_min'],
          qualityMax: json['quality_max'],
          qualityChange: json['quality_change'] ?? 0,
          spoilWeight: json['spoil_weight'] ?? 1,
        ),
        'fluid' => RecipeIngredient._fluid(
          factorioDb: factorioDb,
          name: json['name'],
          amount: json['amount']?.toDouble(),
          temperature: json['temperature']?.toDouble(),
          minimumTemperature: json['minimum_temperature']?.toDouble(),
          maximumTemperature: json['maximum_temperature']?.toDouble(),
        ),
        _ => throw UnimplementedError(),
      };
}

class RecipeProduct {
  final FactorioDatabase factorioDb;

  final String _name;
  final String type;

  late final Item item = factorioDb.itemMap[_name]!;

  final double? amount;
  final double? amountMin;
  final double? amountMax;
  final double ignoredByProductivity;

  final double independentProbability;
  final SharedProbability sharedProbability;
  final double? extraCountFraction;

  final double? percentSpoiled;
  final bool alwaysFresh;

  final String? _qualityMinString;
  final String? _qualityMaxString;
  late final Quality? qualityMin = factorioDb.qualityMap[_qualityMinString];
  late final Quality? qualityMax = factorioDb.qualityMap[_qualityMaxString];

  final int? qualityChange;
  final bool affectedByQuality;

  final double? _givenTemperature;
  late final double? temperature = type == 'fluid'
      ? _givenTemperature ?? (item as FluidItem).defaultTemperature
      : null;

  RecipeProduct._item({
    required this.factorioDb,
    required String name,
    required this.amount,
    required this.amountMin,
    required this.amountMax,
    required this.ignoredByProductivity,
    required this.independentProbability,
    required this.sharedProbability,
    required this.extraCountFraction,
    required this.percentSpoiled,
    required this.alwaysFresh,
    required String? qualityMin,
    required String? qualityMax,
    required this.qualityChange,
    required this.affectedByQuality,
  }) : _name = name,
       type = 'item',
       _qualityMinString = qualityMin,
       _qualityMaxString = qualityMax,
       _givenTemperature = null;

  RecipeProduct._fluid({
    required this.factorioDb,
    required String name,
    required this.amount,
    required this.amountMin,
    required this.amountMax,
    required this.ignoredByProductivity,
    required this.independentProbability,
    required this.sharedProbability,
    required double temperature,
  }) : _name = name,
       type = 'fluid',
       extraCountFraction = null,
       percentSpoiled = null,
       alwaysFresh = true,
       _qualityMinString = null,
       _qualityMaxString = null,
       qualityChange = null,
       affectedByQuality = false,
       _givenTemperature = temperature;

  factory RecipeProduct.fromJson(FactorioDatabase factorioDb, Map json) {
    double? amount = json['amount']?.toDouble();
    double? amountMin = json['amount_min']?.toDouble();
    double? amountMax = json['amount_max']?.toDouble();
    double ignoredByProductivity =
        json['ignored_by_productivity']?.toDouble() ??
        json['ignored_by_stats']?.toDouble() ??
        0;

    double independentProbability =
        json['independent_probability']?.toDouble() ?? 1;
    SharedProbability sharedProbability = json['shared_probability'] != null
        ? SharedProbability.fromJson(json['shared_probability'])
        : SharedProbability.defaultValue;

    return switch (json['type']) {
      'item' => RecipeProduct._item(
        factorioDb: factorioDb,
        name: json['name'],
        amount: amount,
        amountMin: amountMin,
        amountMax: amountMax,
        ignoredByProductivity: ignoredByProductivity,
        independentProbability: independentProbability,
        sharedProbability: sharedProbability,
        extraCountFraction: json['extra_count_fraction']?.toDouble() ?? 0,
        percentSpoiled: json['percent_spoiled']?.toDouble() ?? 0,
        alwaysFresh: json['always_fresh'] ?? false,
        qualityMin: json['quality_min'],
        qualityMax: json['quality_max'],
        qualityChange: json['quality_change'] ?? 0,
        affectedByQuality: json['affected_by_quality'] ?? true,
      ),
      'fluid' => RecipeProduct._fluid(
        factorioDb: factorioDb,
        name: json['name'],
        amount: amount,
        amountMin: amountMin,
        amountMax: amountMax,
        ignoredByProductivity: ignoredByProductivity,
        independentProbability: independentProbability,
        sharedProbability: sharedProbability,
        temperature: json['temperature'],
      ),
      _ => throw UnimplementedError(),
    };
  }
}

class SharedProbability {
  static const defaultValue = SharedProbability._(min: 0, max: 1);
  final double min;
  final double max;

  const SharedProbability._({required this.min, required this.max});

  factory SharedProbability.fromJson(Map json) =>
      SharedProbability._(min: json['min'], max: json['max']);
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
