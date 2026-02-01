part of 'models.dart';

class CraftingMachine {
  // TODO - Quality effects on module and energy usage
  // TODO - EffectReceiver

  String name;
  String? icon;
  double craftingSpeed;
  double energyUsage;
  int moduleSlots;

  CraftingMachineEnergySource? energySource;

  List<String>? craftingCategories;
  List<String>? allowedEffects;

  CraftingMachine._internal(
    this.name,
    this.icon,
    this.craftingSpeed,
    this.energyUsage,
    this.moduleSlots,
    this.energySource,
    this.craftingCategories,
    this.allowedEffects
  );

  factory CraftingMachine.fromJson(Map json) {

    List<String> allowedEffects = const [];
    var rawAllowedEffects = json['allowed_effects'];
    if(rawAllowedEffects is String) {
      allowedEffects = [rawAllowedEffects];
    } else if (rawAllowedEffects is List) {
      allowedEffects = rawAllowedEffects.cast();
    }

    double energyUsage = _convertStringToWatts(json['energy_usage']);

    return CraftingMachine._internal(
      json['name'],
      _getIcon(json),
      json['crafting_speed'].toDouble(),
      energyUsage,
      json['module_slots'] ?? 0,
      CraftingMachineEnergySource.fromJson(json, energyUsage),
      (json['crafting_categories'] as List).cast(),
      allowedEffects
    );
  }
}

class CraftingMachineEnergySource {
  EnergySourceType type;
  Map<String, double> emissionsPerMinute;

  ElectricEnergySource? electric;
  BurnerEnergySource? burner;
  FluidEnergySource? fluid;
  HeatEnergySource? heat;

  CraftingMachineEnergySource._internal(
    this.type,
    this.emissionsPerMinute,
    this.electric,
    this.burner,
    this.fluid,
    this.heat
  );

  factory CraftingMachineEnergySource.fromJson(Map json, double energyUsage) {
    late EnergySourceType type;
    ElectricEnergySource? electric;
    BurnerEnergySource? burner;
    FluidEnergySource? fluid;
    HeatEnergySource? heat;

    switch(json['type'] as String) {
      case 'electric':
        type = EnergySourceType.electric;
        electric = ElectricEnergySource.fromJson(json, energyUsage);
      case 'burner':
        type = EnergySourceType.burner;
        burner = BurnerEnergySource.fromJson(json);
      case 'fluid':
        type = EnergySourceType.fluid;
        fluid = FluidEnergySource.fromJson(json);
      case 'heat':
        type = EnergySourceType.heat;
        heat = HeatEnergySource.fromJson(json);
      case 'void':
      default:
        type = EnergySourceType.fVoid;
    }

    Map<String, double> emissionsPerMinute = (json["emissions-per-minute"] as Map?)?.cast() ?? const {};

    return CraftingMachineEnergySource._internal(
      type,
      emissionsPerMinute,
      electric,
      burner,
      fluid,
      heat
    );
  }
}

// void is a keyword in dart. Can't use that as is
enum EnergySourceType {electric, burner, heat, fluid, fVoid}

class ElectricEnergySource {
  String drain;

  ElectricEnergySource.fromJson(Map json, double energyUsage) :
    drain = json['drain'] ?? (energyUsage / 30);
}

class BurnerEnergySource {
  double effectivity;
  String burnerUsage;
  List<String> fuelCategories;

  BurnerEnergySource.fromJson(Map json) :
    effectivity = json['effectivity'] ?? 1,
    burnerUsage = json['burner_usage'] ?? 'fuel',
    fuelCategories = json['fuel_categories'] ?? const {'chemical'};
}

class FluidEnergySource {
  double effectivity;
  bool burnsFluid;
  double fluidUsagePerTick;

  FluidEnergySource.fromJson(Map json) :
    effectivity = json['effectivity'] ?? 1,
    burnsFluid = json['burns_fluid'] ?? false,
    fluidUsagePerTick = json['fluid_usage_per_tick'] ?? 0;
}

class HeatEnergySource {
  double defaultTemperature;
  double minWorkingTemperature;
  double specificHeat;

  HeatEnergySource.fromJson(Map json) :
    defaultTemperature = json['default_temperature'] ?? 15,
    minWorkingTemperature = json['min_working_temperature'] ?? 15,
    specificHeat = _convertStringToJoules(json['specific_heat']);
}