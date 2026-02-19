part of '../models.dart';

Map<String, double> _parseEmissionsPerMinute(Map energySourceJson) =>
    Map.unmodifiable(
      energySourceJson["emissions_per_minute"] as Map? ?? const {},
    ).cast();

class CraftingMachine {
  // TODO - Quality effects on module and energy usage

  final FactorioDatabase factorioDb;

  final String name;
  final String localisedName;
  final double craftingSpeed;
  final double energyUsage;
  final int moduleSlots;

  final CraftingMachineEnergySource energySource;
  final EffectReceiver effectReceiver;

  final List<String> craftingCategories;
  final List<String> allowedEffects;

  late final List<Recipe> recipes = List.unmodifiable(
    craftingCategories
        .map(
          (category) =>
              factorioDb._craftingCategoryToRecipes[category] ?? const [],
        )
        .expand((i) => i)
        .toSet(),
  );

  CraftingMachine._({
    required this.factorioDb,
    required this.name,
    required this.localisedName,
    required this.craftingSpeed,
    required this.energyUsage,
    required this.moduleSlots,
    required this.energySource,
    required this.effectReceiver,
    required this.craftingCategories,
    required this.allowedEffects,
  });

  factory CraftingMachine.fromJson(FactorioDatabase factorioDb, Map json) {
    List<String> allowedEffects = const [];
    var rawAllowedEffects = json['allowed_effects'];
    if (rawAllowedEffects is String) {
      allowedEffects = List.unmodifiable({rawAllowedEffects});
    } else if (rawAllowedEffects is List) {
      allowedEffects = List.unmodifiable(rawAllowedEffects).cast();
    }

    double energyUsage = _convertStringToEnergy(json['energy_usage'])!;

    return CraftingMachine._(
      factorioDb: factorioDb,
      name: json['name'],
      localisedName: _getLocalisedName(json),
      craftingSpeed: json['crafting_speed'].toDouble(),
      energyUsage: energyUsage,
      moduleSlots: json['module_slots'] ?? 0,
      energySource: CraftingMachineEnergySource.fromJson(
        factorioDb,
        json['energy_source'],
        energyUsage,
      ),
      effectReceiver: EffectReceiver.fromJson(
        json['effect_receiver'] ?? const {},
      ),
      craftingCategories: List.unmodifiable(
        json['crafting_categories'] as List,
      ).cast(),
      allowedEffects: allowedEffects,
    );
  }

  @override
  String toString() => name;
}

class EffectReceiver {
  final BaseEffect baseEffect;
  final bool usesModuleEffects;
  final bool usesBeaconEffects;
  final bool usesSurfaceEffects;

  EffectReceiver._({
    required this.baseEffect,
    required this.usesModuleEffects,
    required this.usesBeaconEffects,
    required this.usesSurfaceEffects,
  });

  factory EffectReceiver.fromJson(Map json) => EffectReceiver._(
    baseEffect: BaseEffect.fromJson(json['base_effect'] ?? const {}),
    usesModuleEffects: json['uses_module_effects'] ?? true,
    usesBeaconEffects: json['uses_beacon_effects'] ?? true,
    usesSurfaceEffects: json['uses_surface_effects'] ?? true,
  );
}

class BaseEffect {
  final double consumption;
  final double speed;
  final double productivity;
  final double pollution;
  final double quality;

  BaseEffect._({
    required this.consumption,
    required this.speed,
    required this.productivity,
    required this.pollution,
    required this.quality,
  });

  factory BaseEffect.fromJson(Map json) => BaseEffect._(
    consumption: json['consumption']?.toDouble() ?? 0,
    speed: json['speed']?.toDouble() ?? 0,
    productivity: json['productivity']?.toDouble() ?? 0,
    pollution: json['pollution']?.toDouble() ?? 0,
    quality: json['quality']?.toDouble() ?? 0,
  );
}

class CraftingMachineEnergySource {
  final FactorioDatabase factorioDb;
  final EnergySourceType type;
  final Map<String, double> emissionsPerMinute;

  CraftingMachineEnergySource._({
    required this.factorioDb,
    required this.type,
    required this.emissionsPerMinute,
  });

  factory CraftingMachineEnergySource.fromJson(
    FactorioDatabase factorioDb,
    Map json,
    double energyUsage,
  ) {
    return switch (json['type'] as String) {
      'electric' => ElectricEnergySource.fromJson(
        factorioDb,
        json,
        energyUsage,
      ),
      'burner' => BurnerEnergySource.fromJson(factorioDb, json),
      // 'fluid' => FluidEnergySource.fromJson(factorioDb, json), TODO
      'heat' => HeatEnergySource.fromJson(factorioDb, json),
      'void' => CraftingMachineEnergySource._(
        factorioDb: factorioDb,
        type: EnergySourceType.fVoid,
        emissionsPerMinute: _parseEmissionsPerMinute(json),
      ),
      _ => throw FactorioException(
        'Unrecognised energy source type - "${json['type']}',
      ),
    };
  }
}

// void is a keyword in dart. Can't use that as is
enum EnergySourceType { electric, burner, heat, fluid, fVoid }

class ElectricEnergySource extends CraftingMachineEnergySource {
  final double drain;

  ElectricEnergySource._({
    required super.factorioDb,
    required this.drain,
    required super.emissionsPerMinute,
  }) : super._(type: EnergySourceType.electric);

  factory ElectricEnergySource.fromJson(
    FactorioDatabase factorioDb,
    Map json,
    double energyUsage,
  ) => ElectricEnergySource._(
    factorioDb: factorioDb,
    drain: _convertStringToEnergy(json['drain']) ?? (energyUsage / 30),
    emissionsPerMinute: _parseEmissionsPerMinute(json),
  );
}

class BurnerEnergySource extends CraftingMachineEnergySource {
  final double effectivity;
  final String burnerUsage;
  final List<String> fuelCategories;
  late final List<SolidItem> fuelItems = List.unmodifiable(
    fuelCategories
        .map(
          (category) => factorioDb._fuelCategoryToItems[category] ?? const [],
        )
        .expand((i) => i)
        .toSet(),
  );

  BurnerEnergySource._({
    required super.factorioDb,
    required this.effectivity,
    required this.burnerUsage,
    required this.fuelCategories,
    required super.emissionsPerMinute,
  }) : super._(type: EnergySourceType.burner);

  factory BurnerEnergySource.fromJson(FactorioDatabase factorioDb, Map json) =>
      BurnerEnergySource._(
        factorioDb: factorioDb,
        effectivity: json['effectivity'].toDouble() ?? 1,
        burnerUsage: json['burner_usage'] ?? 'fuel',
        fuelCategories: List.unmodifiable(
          json['fuel_categories'] as List? ?? const ['chemical'],
        ).cast(),
        emissionsPerMinute: _parseEmissionsPerMinute(json),
      );
}

// class FluidEnergySource extends CraftingMachineEnergySource {
//   final double effectivity;
//   final bool burnsFluid;
//   final double fluidUsagePerTick;
//   final String? filter;
//   final double? minimumTemperature;
//   final double? maximumTemperature;

//   late final List<FluidItem> fuelFluids = filter == null
//       ? factorioDatabase._fluidFuels
//       : List.unmodifiable([factorioDatabase.itemMap[filter]!]);

//   FluidEnergySource._({
//     required super.factorioDatabase,
//     required this.effectivity,
//     required this.burnsFluid,
//     required this.fluidUsagePerTick,
//     required this.filter,
//     required this.minimumTemperature,
//     required this.maximumTemperature,
//     required super.emissionsPerMinute,
//   }) : super._(type: EnergySourceType.fluid);

//   factory FluidEnergySource.fromJson(FactorioDatabase factorioDb, Map json) =>
//       FluidEnergySource._(
//         factorioDatabase: factorioDb,
//         effectivity: json['effectivity']?.toDouble() ?? 1,
//         burnsFluid: json['burns_fluid'] ?? false,
//         fluidUsagePerTick: json['fluid_usage_per_tick']?.toDouble() ?? 0,
//         filter: json['fluid_box']['filter'],
//         minimumTemperature: json['fluid_box']['minimum_temperature'],
//         maximumTemperature: json['fluid_box']['maximum_temperature'],
//         emissionsPerMinute: _parseEmissionsPerMinute(json),
//       );
// }

class HeatEnergySource extends CraftingMachineEnergySource {
  final double defaultTemperature;
  final double maxTemperature;
  final double minWorkingTemperature;
  final double specificHeat;

  HeatEnergySource._({
    required super.factorioDb,
    required this.defaultTemperature,
    required this.maxTemperature,
    required this.minWorkingTemperature,
    required this.specificHeat,
    required super.emissionsPerMinute,
  }) : super._(type: EnergySourceType.heat);

  factory HeatEnergySource.fromJson(FactorioDatabase factorioDb, Map json) =>
      HeatEnergySource._(
        factorioDb: factorioDb,
        defaultTemperature: json['default_temperature']?.toDouble() ?? 15,
        maxTemperature: json['max_temperature'].toDouble(),
        minWorkingTemperature: json['min_working_temperature'].toDouble() ?? 15,
        specificHeat: _convertStringToEnergy(json['specific_heat'])!,
        emissionsPerMinute: _parseEmissionsPerMinute(json),
      );
}
