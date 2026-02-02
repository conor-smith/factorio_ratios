part of 'models.dart';

class CraftingMachine {
  // TODO - Quality effects on module and energy usage
  // TODO - EffectReceiver

  final FactorioDatabase _factorioDb;

  final String name;
  final double craftingSpeed;
  final double energyUsage;
  final int moduleSlots;

  final CraftingMachineEnergySource energySource;

  final List<String> craftingCategories;
  final List<String> allowedEffects;

  late final List<Recipe> recipes = _getRecipes();

  CraftingMachine._internal(
    this._factorioDb,
    this.name,
    this.craftingSpeed,
    this.energyUsage,
    this.moduleSlots,
    this.energySource,
    this.craftingCategories,
    this.allowedEffects,
  );

  factory CraftingMachine.fromJson(FactorioDatabase factorioDb, Map json) {
    List<String> allowedEffects = const [];
    var rawAllowedEffects = json['allowed_effects'];
    if (rawAllowedEffects is String) {
      allowedEffects = List.unmodifiable({rawAllowedEffects});
    } else if (rawAllowedEffects is List) {
      allowedEffects = List.unmodifiable(rawAllowedEffects).cast();
    }

    double energyUsage = _convertStringToEnergy(json['energy_usage'])!;

    return CraftingMachine._internal(
      factorioDb,
      json['name'],
      json['crafting_speed'].toDouble(),
      energyUsage,
      json['module_slots'] ?? 0,
      CraftingMachineEnergySource.fromJson(json, energyUsage),
      List.unmodifiable(json['crafting_categories'] as List).cast(),
      allowedEffects,
    );
  }

  List<Recipe> _getRecipes() {
    Set<Recipe> recipes = {};
    for (var category in craftingCategories) {
      recipes.addAll(
        _factorioDb._craftingCategoriesAndRecipes[category] ?? const [],
      );
    }

    return List.unmodifiable(recipes);
  }
}

class CraftingMachineEnergySource {
  final EnergySourceType type;
  final Map<String, double> emissionsPerMinute;

  CraftingMachineEnergySource._internal(this.type, Map json)
    : emissionsPerMinute = Map.unmodifiable(
        json["emissions_per_minute"] as Map? ?? const {},
      ).cast();

  factory CraftingMachineEnergySource.fromJson(Map json, double energyUsage) {
    return switch (json['type'] as String) {
      'electric' => ElectricEnergySource.fromJson(json, energyUsage),
      'burner' => BurnerEnergySource.fromJson(json),
      'fluid' => FluidEnergySource.fromJson(json),
      'heat' => HeatEnergySource.fromJson(json),
      _ => CraftingMachineEnergySource._internal(EnergySourceType.fVoid, json),
    };
  }
}

// void is a keyword in dart. Can't use that as is
enum EnergySourceType { electric, burner, heat, fluid, fVoid }

class ElectricEnergySource extends CraftingMachineEnergySource {
  final double drain;

  ElectricEnergySource.fromJson(Map json, double energyUsage)
    : drain = _convertStringToEnergy(json['drain']) ?? (energyUsage / 30),
      super._internal(EnergySourceType.electric, json);
}

class BurnerEnergySource extends CraftingMachineEnergySource {
  final double effectivity;
  final String burnerUsage;
  final List<String> fuelCategories;

  BurnerEnergySource.fromJson(Map json)
    : effectivity = json['effectivity'] ?? 1,
      burnerUsage = json['burner_usage'] ?? 'fuel',
      fuelCategories = List.unmodifiable(
        json['fuel_categories'] as List? ?? const ['chemical'],
      ).cast(),
      super._internal(EnergySourceType.burner, json);
}

class FluidEnergySource extends CraftingMachineEnergySource {
  final double effectivity;
  final bool burnsFluid;
  final double fluidUsagePerTick;

  FluidEnergySource.fromJson(Map json)
    : effectivity = json['effectivity']?.toDouble() ?? 1,
      burnsFluid = json['burns_fluid'] ?? false,
      fluidUsagePerTick = json['fluid_usage_per_tick']?.toDouble() ?? 0,
      super._internal(EnergySourceType.fluid, json);
}

class HeatEnergySource extends CraftingMachineEnergySource {
  final double defaultTemperature;
  final double maxTemperature;
  final double minWorkingTemperature;
  final double specificHeat;

  HeatEnergySource.fromJson(Map json)
    : defaultTemperature = json['default_temperature']?.toDouble() ?? 15,
      maxTemperature = json['max_temperature'].toDouble(),
      minWorkingTemperature = json['min_working_temperature'].toDouble() ?? 15,
      specificHeat = _convertStringToEnergy(json['specific_heat'])!,
      super._internal(EnergySourceType.heat, json);
}
