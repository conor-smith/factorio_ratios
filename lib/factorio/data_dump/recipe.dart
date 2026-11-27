part of 'data_dump.dart';

class RecipeJson extends PrototypeWithIconJson {
  final List<String> categories;

  final List<RecipeIngredientJson> ingredients;
  final List<RecipeProductJson> results;

  final String? mainProduct;

  final double energyRequired;
  final double emissionsMultiplier;
  final double maximumProductivity;

  final bool enabled;
  final bool hideFromStats;

  final List<SurfaceCondition>? surfaceConditions;

  final bool allowConsumption;
  final bool allowSpeed;
  final bool allowProductivity;
  final bool allowPollution;
  final bool allowQuality;

  final List<String>? allowedModuleCategories;

  final bool canSetQuality;

  RecipeJson._({
    required super.name,
    required super.type,
    required super.order,
    required super.subgroupName,
    required super.localisedName,
    required super.icon,
    required List<String>? categories,
    required Iterable<RecipeIngredientJson> ingredients,
    required Iterable<RecipeProductJson> results,
    required this.mainProduct,
    required double? energyRequired,
    required double? emissionsMultiplier,
    required double? maximumProductivity,
    required bool? enabled,
    required bool? hideFromStats,
    required Iterable<SurfaceCondition>? surfaceConditions,
    required bool? allowConsumption,
    required bool? allowSpeed,
    required bool? allowProductivity,
    required bool? allowPollution,
    required bool? allowQuality,
    required Iterable<String>? allowedModuleCategories,
    required bool? canSetQuality,
  }) : categories = _unmodifiableOrNullList(categories) ?? const ['crafting'],
       ingredients = List.unmodifiableOf(ingredients),
       results = List.unmodifiableOf(results),
       energyRequired = energyRequired ?? 0.5,
       emissionsMultiplier = emissionsMultiplier ?? 1,
       maximumProductivity = maximumProductivity ?? 3,
       enabled = enabled ?? true,
       hideFromStats = hideFromStats ?? false,
       surfaceConditions = _unmodifiableOrNullList(surfaceConditions),
       allowConsumption = allowConsumption ?? true,
       allowSpeed = allowSpeed ?? true,
       allowProductivity = allowProductivity ?? false,
       allowPollution = allowPollution ?? true,
       allowQuality = allowQuality ?? true,
       allowedModuleCategories = _unmodifiableOrNullList(
         allowedModuleCategories,
       ),
       canSetQuality = canSetQuality ?? true,
       super._();

  factory RecipeJson.fromJson(Map json) {
    // Empty ingredients are serialised as "{}" in json rather than null or "[]"
    // As such, a factory method is needed
    late Iterable<RecipeIngredientJson> ingredients;
    var rawIngredients = json['ingredients'];
    if (rawIngredients is List) {
      ingredients = rawIngredients.map(
        (ingredientJson) => RecipeIngredientJson.fromJson(ingredientJson),
      );
    } else {
      ingredients = const [];
    }

    late Iterable<RecipeProductJson> results;
    var rawResults = json['results'];
    if (rawResults is List) {
      results = rawResults.map(
        (resultJson) => RecipeProductJson.fromJson(resultJson),
      );
    } else {
      results = const [];
    }

    Iterable<SurfaceCondition>? surfaceConditions =
        (json['surface_conditions'] as List?)?.cast<Map>().map(
          (scJson) => SurfaceCondition.fromJson(scJson),
        );

    return RecipeJson._(
      name: json['name'],
      type: json['type'],
      order: json['order'],
      subgroupName: json['subgroup'],
      localisedName: json['localised_name'],
      icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
      mainProduct: json['main_product'],
      categories: json['categories']?.cast<String>(),
      energyRequired: json['energy_required']?.toDouble(),
      maximumProductivity: json['maximum_productivity']?.toDouble(),
      emissionsMultiplier: json['emissions_multiplier']?.toDouble(),
      enabled: json['enabled'],
      allowConsumption: json['allow_consumption'],
      allowSpeed: json['allow_speed'],
      allowProductivity: json['allow_productivity'],
      allowPollution: json['allow_pollution'],
      allowQuality: json['allow_quality'],
      canSetQuality: json['can_set_quality'],
      ingredients: ingredients,
      results: results,
      surfaceConditions: surfaceConditions,
      hideFromStats: json['hide_from_stats'],
      allowedModuleCategories: json['allowed_module_categories'],
    );
  }
}

abstract class RecipeIngredientJson {
  final String name;
  final String type;
  final double amount;
  final double ignoredByStats;

  RecipeIngredientJson._({
    required this.name,
    required this.type,
    required this.amount,
    required double? ignoredByStats,
  }) : ignoredByStats = ignoredByStats ?? 0;

  factory RecipeIngredientJson.fromJson(Map json) => switch (json['type']) {
    'item' => RecipeItemIngredientJson.fromJson(json),
    'fluid' => RecipeFluidIngredientJson.fromJson(json),
    _ => throw FactorioException(
      'Unrecognised ingredient type: ${json['type']}',
    ),
  };
}

class RecipeItemIngredientJson extends RecipeIngredientJson {
  final String? qualityMin;
  final String? qualityMax;
  final int qualityChange;
  final double spoilWeight;

  RecipeItemIngredientJson._({
    required super.name,
    required super.type,
    required super.amount,
    required super.ignoredByStats,
    required this.qualityMin,
    required this.qualityMax,
    required int? qualityChange,
    required double? spoilWeight,
  }) : qualityChange = qualityChange ?? 0,
       spoilWeight = spoilWeight ?? 1,
       super._();

  RecipeItemIngredientJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        amount: json['amount'].toDouble(),
        ignoredByStats: json['ignored_by_stats']?.toDouble(),
        qualityMin: json['quality_min'],
        qualityMax: json['quality_max'],
        qualityChange: json['quality_change'],
        spoilWeight: json['spoil_weight']?.toDouble(),
      );
}

class RecipeFluidIngredientJson extends RecipeIngredientJson {
  final double? temperature;
  final double? minimumTemperature;
  final double? maximumTemperature;

  RecipeFluidIngredientJson._({
    required super.name,
    required super.type,
    required super.amount,
    required super.ignoredByStats,
    required this.temperature,
    required this.minimumTemperature,
    required this.maximumTemperature,
  }) : super._();

  RecipeFluidIngredientJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        amount: json['amount'].toDouble(),
        ignoredByStats: json['ignored_by_stats']?.toDouble(),
        temperature: json['temperature']?.toDouble(),
        minimumTemperature: json['minimum_temperature']?.toDouble(),
        maximumTemperature: json['maximum_temperature']?.toDouble(),
      );
}

abstract class RecipeProductJson {
  final String name;
  final String type;

  final double? amount;
  final double? amountMin;
  final double? amountMax;

  final double ignoredByStats;
  final double ignoredByProductivity;

  final double independentProbability;
  final SharedProbability sharedProbability;

  RecipeProductJson._({
    required this.name,
    required this.type,
    required this.amount,
    required this.amountMin,
    required this.amountMax,
    required double? ignoredByStats,
    required double? ignoredByProductivity,
    required double? independentProbability,
    required SharedProbability? sharedProbability,
  }) : ignoredByStats = ignoredByStats ?? 0,
       ignoredByProductivity = ignoredByProductivity ?? ignoredByStats ?? 0,
       independentProbability = independentProbability ?? 1,
       sharedProbability =
           sharedProbability ?? const SharedProbability._(min: 0, max: 1);

  factory RecipeProductJson.fromJson(Map json) => switch (json['type']) {
    'item' => RecipeItemProductJson.fromJson(json),
    'fluid' => RecipeFluidProductJson.fromJson(json),
    _ => throw FactorioException('Unrecognised product type: ${json['type']}'),
  };
}

class RecipeItemProductJson extends RecipeProductJson {
  final double extraCountFraction;
  final double percentSpoiled;
  final bool alwaysFresh;
  final bool resetFreshnessOnCraft;

  final String? qualityMin;
  final String? qualityMax;
  final int qualityChange;
  final bool affectedByQuality;

  RecipeItemProductJson._({
    required super.name,
    required super.type,
    required super.amount,
    required super.amountMin,
    required super.amountMax,
    required super.ignoredByStats,
    required super.ignoredByProductivity,
    required super.independentProbability,
    required super.sharedProbability,
    required double? extraCountFraction,
    required double? percentSpoiled,
    required bool? alwaysFresh,
    required bool? resetFreshnessOnCraft,
    required this.qualityMin,
    required this.qualityMax,
    required int? qualityChange,
    required bool? affectedByQuality,
  }) : extraCountFraction = extraCountFraction ?? 0,
       percentSpoiled = percentSpoiled ?? 0,
       alwaysFresh = alwaysFresh ?? false,
       resetFreshnessOnCraft = resetFreshnessOnCraft ?? false,
       qualityChange = qualityChange ?? 0,
       affectedByQuality = affectedByQuality ?? true,
       super._();

  RecipeItemProductJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        amount: json['amount']?.toDouble(),
        amountMin: json['amount_min']?.toDouble(),
        amountMax: json['amount_max']?.toDouble(),
        ignoredByStats: json['ignored_by_stats']?.toDouble(),
        ignoredByProductivity: json['ignored_by_productivity']?.toDouble(),
        independentProbability: json['independent_probability']?.toDouble(),
        sharedProbability: json['shared_probability'] != null
            ? SharedProbability.fromJson(json['shared_probability'])
            : null,
        extraCountFraction: json['extra_count_fraction']?.toDouble(),
        percentSpoiled: json['percent_spoiled']?.toDouble(),
        alwaysFresh: json['always_fresh'],
        resetFreshnessOnCraft: json['reset_freshness_on_craft'],
        qualityMin: json['quality_min'],
        qualityMax: json['quality_max'],
        qualityChange: json['quality_change'],
        affectedByQuality: json['affected_by_quality'],
      );
}

class RecipeFluidProductJson extends RecipeProductJson {
  final double? temperature;

  RecipeFluidProductJson._({
    required super.name,
    required super.type,
    required super.amount,
    required super.amountMin,
    required super.amountMax,
    required super.ignoredByStats,
    required super.ignoredByProductivity,
    required super.independentProbability,
    required super.sharedProbability,
    required this.temperature,
  }) : super._();

  RecipeFluidProductJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        amount: json['amount']?.toDouble(),
        amountMin: json['amount_min']?.toDouble(),
        amountMax: json['amount_max']?.toDouble(),
        ignoredByStats: json['ignored_by_stats']?.toDouble(),
        ignoredByProductivity: json['ignored_by_productivity']?.toDouble(),
        independentProbability: json['independent_probability']?.toDouble(),
        sharedProbability: json['shared_probability'] != null
            ? SharedProbability.fromJson(json['shared_probability'])
            : null,
        temperature: json['temperature']?.toDouble(),
      );
}

class SharedProbability {
  final double min;
  final double max;

  const SharedProbability._({required this.min, required this.max});

  factory SharedProbability.fromJson(Map json) => SharedProbability._(
    min: json['min'].toDouble(),
    max: json['max'].toDouble(),
  );
}

class SurfaceCondition {
  final String property;
  final double min;
  final double max;

  SurfaceCondition._({
    required this.property,
    required double? min,
    required double? max,
  }) : min = min ?? double.negativeInfinity,
       max = max ?? double.infinity;

  factory SurfaceCondition.fromJson(Map json) => SurfaceCondition._(
    property: json['property'],
    min: json['min']?.toDouble(),
    max: json['max']?.toDouble(),
  );
}
