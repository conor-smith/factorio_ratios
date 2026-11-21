part of 'data_dump.dart';

class DDRecipe extends DDPrototypeWithIcon {
  final List<String> categories;

  final List<DDRecipeIngredient> ingredients;
  final List<DDRecipeProduct> results;

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

  DDRecipe._(
    Map json, {
    required List<String>? categories,
    required Iterable<DDRecipeIngredient> ingredients,
    required Iterable<DDRecipeProduct> results,
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
       ingredients = List.unmodifiable(ingredients),
       results = List.unmodifiable(results),
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
       super.fromJson(json, ExpectedIconSize.other);

  factory DDRecipe.fromJson(Map json) {
    // Empty ingredients are serialised as "{}" in json rather than null or "[]"
    // As such, a factory method is needed
    late Iterable<DDRecipeIngredient> ingredients;
    var rawIngredients = json['ingredients'] ?? const [];
    if (rawIngredients is List) {
      ingredients = rawIngredients.map(
        (ingredientJson) => DDRecipeIngredient.fromJson(ingredientJson),
      );
    } else {
      ingredients = const [];
    }

    late Iterable<DDRecipeProduct> results;
    var rawResults = json['results'] ?? const [];
    if (rawResults is List) {
      results = rawResults.map(
        (resultJson) => DDRecipeProduct.fromJson(resultJson),
      );
    } else {
      results = const [];
    }

    Iterable<SurfaceCondition>? surfaceConditions = json['surface_conditions']
        ?.map((scJson) => SurfaceCondition.fromJson(scJson));

    return DDRecipe._(
      json,
      mainProduct: json['main_product'],
      categories: json['categories'],
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

abstract class DDRecipeIngredient {
  final String name;
  final String type;
  final double amount;
  final double ignoredByStats;

  DDRecipeIngredient({
    required this.name,
    required this.type,
    required this.amount,
    required double? ignoredByStats,
  }) : ignoredByStats = ignoredByStats ?? 0;

  DDRecipeIngredient._fromJson(Map json)
    : this(
        name: json['name'],
        type: json['type'],
        amount: json['amount'].toDouble(),
        ignoredByStats: json['ignored_by_stats']?.toDouble(),
      );

  factory DDRecipeIngredient.fromJson(Map json) => switch (json['type']) {
    'item' => DDRecipeIngredient.fromJson(json),
    'fluid' => DDRecipeFluidIngredient.fromJson(json),
    _ => throw FactorioException(
      'Unrecognised ingredient type: ${json['type']}',
    ),
  };
}

class DDRecipeItemIngredient extends DDRecipeIngredient {
  final String? qualityMin;
  final String? qualityMax;
  final int qualityChange;
  final double spoilWeight;

  DDRecipeItemIngredient._(
    super.json, {
    required this.qualityMin,
    required this.qualityMax,
    required int? qualityChange,
    required double? spoilWeight,
  }) : qualityChange = qualityChange ?? 0,
       spoilWeight = spoilWeight ?? 1,
       super._fromJson();

  DDRecipeItemIngredient.fromJson(Map json)
    : this._(
        json,
        qualityMin: json['quality_min'],
        qualityMax: json['quality_max'],
        qualityChange: json['quality_change'],
        spoilWeight: json['spoil_weight']?.toDouble(),
      );
}

class DDRecipeFluidIngredient extends DDRecipeIngredient {
  final double? temperature;
  final double? minimumTemperature;
  final double? maximumTemperature;

  DDRecipeFluidIngredient._(
    super.json, {
    required this.temperature,
    required this.minimumTemperature,
    required this.maximumTemperature,
  }) : super._fromJson();

  DDRecipeFluidIngredient.fromJson(Map json)
    : this._(
        json,
        temperature: json['temperature']?.toDouble(),
        minimumTemperature: json['minimum_temperature']?.toDouble(),
        maximumTemperature: json['maximum_temperature']?.toDouble(),
      );
}

abstract class DDRecipeProduct {
  final String name;
  final String type;

  final double? amount;
  final double? amountMin;
  final double? amountMax;

  final double ignoredByStats;
  final double ignoredByProductivity;

  final double independentProbability;
  final SharedProbability sharedProbability;

  DDRecipeProduct({
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

  DDRecipeProduct._fromJson(Map json)
    : this(
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
      );

  factory DDRecipeProduct.fromJson(Map json) => switch (json['type']) {
    'item' => DDRecipeItemProduct.fromJson(json),
    'fluid' => DDRecipeFluidProduct.fromJson(json),
    _ => throw FactorioException('Unrecognised product type: ${json['type']}'),
  };
}

class DDRecipeItemProduct extends DDRecipeProduct {
  final double extraCountFraction;
  final double percentSpoiled;
  final bool alwaysFresh;
  final bool resetFreshnessOnCraft;

  final String? qualityMin;
  final String? qualityMax;
  final int qualityChange;
  final bool affectedByQuality;

  DDRecipeItemProduct._(
    super.json, {
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
       super._fromJson();

  DDRecipeItemProduct.fromJson(Map json)
    : this._(
        json,
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

class DDRecipeFluidProduct extends DDRecipeProduct {
  final double? temperature;

  DDRecipeFluidProduct._(super.json, {required this.temperature})
    : super._fromJson();

  DDRecipeFluidProduct.fromJson(Map json)
    : this._(json, temperature: json['temperature']);
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
