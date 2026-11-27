part of 'data_dump.dart';

class CraftingMachineJson
    with PrototypeToString
    implements PrototypeWithIconJson {
  @override
  final String name;
  @override
  final String type;
  @override
  final String order;
  @override
  final String? subgroupName;
  @override
  final dynamic localisedName;
  @override
  final Icon? icon;

  final bool qualityAffectsEnergyUsage;
  final String energyUsage;
  final double craftingSpeed;
  final List<String> craftingCategories;
  final CraftingMachineEnergySource energySource;
  final EffectReceiver? effectReceiver;
  final int moduleSlots;
  final bool qualityAffectsModuleSlots;

  final List<String>? allowedEffects;
  final List<String>? allowedModuleCategories;

  final Map<String, double>? craftingSpeedQualityMultiplier;
  final Map<String, int>? moduleSlotsQualityBonus;
  final Map<String, double>? energyUsageQualityMultiplier;

  CraftingMachineJson._({
    required this.name,
    required this.type,
    required String? order,
    required this.subgroupName,
    required dynamic localisedName,
    required this.icon,
    required bool? qualityAffectsEnergyUsage,
    required this.energyUsage,
    required this.craftingSpeed,
    required List<String> craftingCategories,
    required this.energySource,
    required this.effectReceiver,
    required int? moduleSlots,
    required bool? qualityAffectsModuleSlots,
    required List<String>? allowedEffects,
    required List<String>? allowedModuleCategories,
    required Map<String, double>? craftingSpeedQualityMultiplier,
    required Map<String, int>? moduleSlotsQualityBonus,
    required Map<String, double>? energyUsageQualityMultiplier,
  }) : order = order ?? PrototypeJson._defaultOrder,
       localisedName = _unmodifiableLocalisedString(localisedName),
       qualityAffectsEnergyUsage = qualityAffectsEnergyUsage ?? false,
       craftingCategories = List.unmodifiableOf(craftingCategories),
       moduleSlots = moduleSlots ?? 0,
       qualityAffectsModuleSlots = qualityAffectsModuleSlots ?? false,
       allowedEffects = _unmodifiableOrNullList(allowedEffects),
       allowedModuleCategories = _unmodifiableOrNullList(
         allowedModuleCategories,
       ),
       craftingSpeedQualityMultiplier = _unmodifiableOrNullMap(
         craftingSpeedQualityMultiplier,
       ),
       moduleSlotsQualityBonus = _unmodifiableOrNullMap(
         moduleSlotsQualityBonus,
       ),
       energyUsageQualityMultiplier = _unmodifiableOrNullMap(
         energyUsageQualityMultiplier,
       );

  factory CraftingMachineJson.fromJson(Map json) {
    List<String>? allowedEffects;
    var rawAllowedEffects = json['allowed_effects'];
    if (rawAllowedEffects is String) {
      allowedEffects = [rawAllowedEffects];
    } else if (rawAllowedEffects is List) {
      allowedEffects = rawAllowedEffects.cast();
    }

    Map? rawcsqm = json['crafting_speed_quality_multiplier'];
    Map<String, double>? craftingSpeedQualityMultiplier = rawcsqm?.map(
      (key, value) => MapEntry(key, value.toDouble()),
    );

    Map<String, int>? moduleSlotsQualityBonus =
        (json['module_slots_quality_bonus'] as Map?)?.cast();

    Map? raweuqm = json['energy_usage_quality_multiplier'];
    Map<String, double>? energyUsageQualityMultiplier = raweuqm?.map(
      (key, value) => MapEntry(key, value.toDouble()),
    );

    Map? effectReceiverJson = json['effect_receiver'] as Map?;
    EffectReceiver? effectReceiver = effectReceiverJson != null
        ? EffectReceiver.fromJson(effectReceiverJson)
        : null;

    return CraftingMachineJson._(
      name: json['name'],
      type: json['type'],
      order: json['order'],
      subgroupName: json['subgroup'],
      localisedName: json['localised_name'],
      icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
      craftingSpeed: json['crafting_speed'].toDouble(),
      energyUsage: json['energy_usage'],
      moduleSlots: json['module_slots'],
      energySource: CraftingMachineEnergySource.fromJson(json['energy_source']),
      effectReceiver: effectReceiver,
      craftingCategories: (json['crafting_categories'] as List).cast(),
      allowedEffects: allowedEffects,
      qualityAffectsEnergyUsage: json['quality_affects_energy_usage'],
      allowedModuleCategories: (json['allowed_module_categories'] as List?)
          ?.cast(),
      qualityAffectsModuleSlots: json['quality_affects_module_slots'],
      craftingSpeedQualityMultiplier: craftingSpeedQualityMultiplier,
      moduleSlotsQualityBonus: moduleSlotsQualityBonus,
      energyUsageQualityMultiplier: energyUsageQualityMultiplier,
    );
  }
}

class EffectReceiver {
  final BaseEffect? baseEffect;
  final bool usesModuleEffects;
  final bool usesBeaconEffects;
  final bool usesSurfaceEffects;
  final bool usesLocalEffects;
  final EffectValueRange consumptionLimits;
  final EffectValueRange speedLimits;
  final EffectValueRange productivityLimits;
  final EffectValueRange pollutionLimits;
  final EffectValueRange qualityLimits;

  EffectReceiver._({
    required this.baseEffect,
    required bool? usesModuleEffects,
    required bool? usesBeaconEffects,
    required bool? usesSurfaceEffects,
    required bool? usesLocalEffects,
    required EffectValueRange? consumptionLimits,
    required EffectValueRange? speedLimits,
    required EffectValueRange? productivityLimits,
    required EffectValueRange? pollutionLimits,
    required EffectValueRange? qualityLimits,
  }) : usesModuleEffects = usesModuleEffects ?? true,
       usesBeaconEffects = usesBeaconEffects ?? true,
       usesSurfaceEffects = usesSurfaceEffects ?? true,
       usesLocalEffects = usesLocalEffects ?? true,
       consumptionLimits =
           consumptionLimits ?? const EffectValueRange._(low: -0.8, high: 1000),
       speedLimits =
           speedLimits ?? const EffectValueRange._(low: -0.8, high: 1000),
       productivityLimits =
           productivityLimits ??
           const EffectValueRange._(low: -0.8, high: 1000),
       pollutionLimits =
           pollutionLimits ?? const EffectValueRange._(low: -0.8, high: 1000),
       qualityLimits =
           qualityLimits ?? const EffectValueRange._(low: 0, high: 1000);

  factory EffectReceiver.fromJson(Map json) {
    Map? baseEffectJson = json['base_effect'];
    var baseEffect = baseEffectJson != null
        ? BaseEffect.fromJson(baseEffectJson)
        : null;

    Map? consumptionLimitsJson = json['consumption_limits'];
    var consumptionLimits = consumptionLimitsJson != null
        ? EffectValueRange.fromJson(consumptionLimitsJson)
        : null;
    Map? speedLimitsJson = json['speed_limits'];
    var speedLimits = speedLimitsJson != null
        ? EffectValueRange.fromJson(speedLimitsJson)
        : null;
    Map? productivityLimitsJson = json['productivity_limits'];
    var productivityLimits = productivityLimitsJson != null
        ? EffectValueRange.fromJson(productivityLimitsJson)
        : null;
    Map? pollutionLimitsJson = json['pollution_limits'];
    var pollutionLimits = pollutionLimitsJson != null
        ? EffectValueRange.fromJson(pollutionLimitsJson)
        : null;
    Map? qualityLimitsJson = json['quality_limits'];
    var qualityLimits = qualityLimitsJson != null
        ? EffectValueRange.fromJson(qualityLimitsJson)
        : null;

    return EffectReceiver._(
      baseEffect: baseEffect,
      usesModuleEffects: json['uses_module_effects'],
      usesBeaconEffects: json['uses_beacon_effects'],
      usesSurfaceEffects: json['uses_surface_effects'],
      usesLocalEffects: json['uses_local_effects'],
      consumptionLimits: consumptionLimits,
      speedLimits: speedLimits,
      productivityLimits: productivityLimits,
      pollutionLimits: pollutionLimits,
      qualityLimits: qualityLimits,
    );
  }
}

class BaseEffect {
  final double? consumption;
  final double? speed;
  final double? productivity;
  final double? pollution;
  final double? quality;

  BaseEffect._({
    required this.consumption,
    required this.speed,
    required this.productivity,
    required this.pollution,
    required this.quality,
  });

  BaseEffect.fromJson(Map json)
    : this._(
        consumption: json['consumption']?.toDouble(),
        speed: json['speed']?.toDouble(),
        productivity: json['productivity']?.toDouble(),
        pollution: json['pollution']?.toDouble(),
        quality: json['quality']?.toDouble(),
      );
}

class EffectValueRange {
  final double? low;
  final double? high;

  const EffectValueRange._({required this.low, required this.high});

  EffectValueRange.fromJson(Map json)
    : this._(low: json['low']?.toDouble(), high: json['high']?.toDouble());
}

abstract class CraftingMachineEnergySource {
  EnergySourceType get type;
  Map<String, double>? get emissionsPerMinute;

  factory CraftingMachineEnergySource.fromJson(Map json) =>
      switch (json['type']) {
        'electric' => ElectricEnergySource.fromJson(json),
        'burner' => BurnerEnergySource.fromJson(json),
        'fluid' => FluidEnergySource.fromJson(json),
        'heat' => HeatEnergySource.fromJson(json),
        'void' => VoidEnergySource.fromJson(json),
        _ => throw FactorioException(
          'Unrecognised energy source type - "${json['type']}',
        ),
      };
}

// void is a keyword in dart. Can't use that as is
enum EnergySourceType {
  electric('electric'),
  burner('burner'),
  heat('heat'),
  fluid('fluid'),
  fVoid('void');

  final String name;

  const EnergySourceType(this.name);

  @override
  String toString() => name;
}

class ElectricEnergySource implements CraftingMachineEnergySource {
  @override
  EnergySourceType get type => EnergySourceType.electric;

  @override
  final Map<String, double>? emissionsPerMinute;

  final String? drain;

  ElectricEnergySource._({
    required this.drain,
    required Map<String, double>? emissionsPerMinute,
  }) : emissionsPerMinute = _unmodifiableOrNullMap(emissionsPerMinute);

  ElectricEnergySource.fromJson(Map json)
    : this._(
        drain: json['drain'],
        emissionsPerMinute: _parseStringDoubleMap(json['emissions_per_minute']),
      );
}

class BurnerEnergySource implements CraftingMachineEnergySource {
  @override
  EnergySourceType get type => EnergySourceType.burner;

  @override
  final Map<String, double>? emissionsPerMinute;

  final double effectivity;
  final String burnerUsage;
  final List<String> fuelCategories;
  final bool hideFromStats;

  BurnerEnergySource._({
    required double? effectivity,
    required String? burnerUsage,
    required List<String>? fuelCategories,
    required bool? hideFromStats,
    required Map<String, double>? emissionsPerMinute,
  }) : effectivity = effectivity ?? 1,
       burnerUsage = burnerUsage ?? 'fuel',
       fuelCategories =
           _unmodifiableOrNullList(fuelCategories) ?? const ['chemical'],
       hideFromStats = hideFromStats ?? false,
       emissionsPerMinute = _unmodifiableOrNullMap(emissionsPerMinute);

  BurnerEnergySource.fromJson(Map json)
    : this._(
        effectivity: json['effectivity'].toDouble(),
        burnerUsage: json['burner_usage'],
        fuelCategories: (json['fuel_categories'] as List?)?.cast(),
        emissionsPerMinute: _parseStringDoubleMap(json['emissions_per_minute']),
        hideFromStats: json['hide_from_stats'],
      );
}

class FluidEnergySource implements CraftingMachineEnergySource {
  @override
  EnergySourceType get type => EnergySourceType.fluid;

  @override
  final Map<String, double>? emissionsPerMinute;

  final double effectivity;
  final bool burnsFluid;
  final bool scaleFluidUsage;
  final bool hideFromStats;
  final double? fluidUsagePerTick;
  final String? filter;
  final double? maximumTemperature;
  final double? minimumInputTemperature;
  final double? maximumInputTemperature;
  final SpentFluidSpecification? spentFluid;

  FluidEnergySource._({
    required double? effectivity,
    required bool? burnsFluid,
    required bool? scaleFluidUsage,
    required bool? hideFromStats,
    required this.fluidUsagePerTick,
    required this.filter,
    required this.maximumTemperature,
    required this.minimumInputTemperature,
    required this.maximumInputTemperature,
    required this.spentFluid,
    required Map<String, double>? emissionsPerMinute,
  }) : effectivity = effectivity ?? 1,
       burnsFluid = burnsFluid ?? false,
       scaleFluidUsage = scaleFluidUsage ?? false,
       hideFromStats = hideFromStats ?? false,
       emissionsPerMinute = _unmodifiableOrNullMap(emissionsPerMinute);

  factory FluidEnergySource.fromJson(Map json) {
    Map? spentFluidJson = json['spent_fluid'];
    var spentFluid = spentFluidJson != null
        ? SpentFluidSpecification.fromJson(spentFluidJson)
        : null;

    return FluidEnergySource._(
      effectivity: json['effectivity']?.toDouble(),
      burnsFluid: json['burns_fluid'],
      scaleFluidUsage: json['scale_fluid_usage'],
      hideFromStats: json['hide_from_stats'],
      fluidUsagePerTick: json['fluid_usage_per_tick']?.toDouble(),
      filter: json['fluid_box']['filter'],
      maximumTemperature: json['maximum_temperature']?.toDouble(),
      minimumInputTemperature: json['minimum_input_temperature']?.toDouble(),
      maximumInputTemperature: json['maximum_input_temperature']?.toDouble(),
      spentFluid: spentFluid,
      emissionsPerMinute: _parseStringDoubleMap(json['emissions_per_minute']),
    );
  }
}

class HeatEnergySource implements CraftingMachineEnergySource {
  @override
  EnergySourceType get type => EnergySourceType.heat;

  @override
  final Map<String, double>? emissionsPerMinute;

  final double maxTemperature;
  final String specificHeat;
  final double defaultTemperature;
  final double minWorkingTemperature;

  HeatEnergySource._({
    required this.maxTemperature,
    required this.specificHeat,
    required double? defaultTemperature,
    required double? minWorkingTemperature,
    required Map<String, double>? emissionsPerMinute,
  }) : defaultTemperature = defaultTemperature ?? 15,
       minWorkingTemperature = minWorkingTemperature ?? 15,
       emissionsPerMinute = _unmodifiableOrNullMap(emissionsPerMinute);

  HeatEnergySource.fromJson(Map json)
    : this._(
        defaultTemperature: json['default_temperature']?.toDouble(),
        maxTemperature: json['max_temperature'].toDouble(),
        minWorkingTemperature: json['min_working_temperature'].toDouble(),
        specificHeat: json['specific_heat'],
        emissionsPerMinute: _parseStringDoubleMap(json['emissions_per_minute']),
      );
}

class VoidEnergySource implements CraftingMachineEnergySource {
  @override
  EnergySourceType get type => EnergySourceType.fVoid;

  @override
  final Map<String, double>? emissionsPerMinute;

  VoidEnergySource._({required Map<String, double>? emissionsPerMinute})
    : emissionsPerMinute = _unmodifiableOrNullMap(emissionsPerMinute);

  VoidEnergySource.fromJson(Map json)
    : this._(
        emissionsPerMinute: _parseStringDoubleMap(json['emissions_per_minute']),
      );
}
