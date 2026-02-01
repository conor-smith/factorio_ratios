import 'package:logging/logging.dart';

// TODO - either add fluid class or make item and fluid parent / child

double _convertStringToWatts(String energyUsage) {
  // TODO
  return 0;
}

double _convertStringToJoules(String energy) {
  // TODO
  return 0;
}

class FactorioDatabase {
  List<Item> items;
  List<Recipe> recipes;
  List<CraftingMachine> craftingMachines;

  FactorioDatabase(this.items, this.recipes, this.craftingMachines);
}

// TODO
const String _defaultIcon = 'TODO';

final Logger _logger = Logger('FactorioModels');

class Item {
  String name;
  String icon;
  int stackSize;

  String? fuelCategory;
  String? fuelValue;
  String? burntResult;

  int spoilTicks;
  String? spoilResult;

  Item._internal(
    this.name,
    this.icon,
    this.stackSize,
    this.fuelCategory,
    this.fuelValue,
    this.burntResult,
    this.spoilTicks,
    this.spoilResult
  );

  factory Item.fromJson(Map json) {
    String? icon = json['icon'] ?? json['icons']?[0]?['icon'];
    if(icon == null) {
      _logger.info('Item "${json['name']}" has no icon or icon list');
    }

    return Item._internal(
      json['name'],
      icon ?? _defaultIcon,
      json['stack_size'],
      json['fuel_category'],
      json['fuel_value'],
      json['burnt_result'],
      json['spoil_ticks'] ?? 0,
      json['spoilResult']
    );
  }
}

// TODO - Recipes with only one output will use icon of said output if icon or icons is empty
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
    String? icon = json['icon'] ?? json['icons']?[0]?['icon'];
    if(icon == null) {
      _logger.info('Recipe "${json['name']}" has no icon or icon list');
    }

    return Recipe._internal(
      json['name'],
      icon,
      json['category'] ?? 'crafting',
      json['energy_required']?.toDouble() ?? 0.5,
      json['maximum_productivity']?.toDouble() ?? 3,
      json['emissions_multiplier']?.toDouble() ?? 1,
      json['enabled'] ?? true,
      json['allowConsumption'] ?? true,
      json['allow_speed'] ?? true,
      json['allow_productivity'] ?? false,
      json['allow_pollution'] ?? true,
      json['allow_quality'] ?? true,
      const [],
      const [],
      const []
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
    probability = json['probability'].toDouble() ?? 1;
}

class SurfaceCondition {
  String property;
  double min;
  double max;

  SurfaceCondition.fromJson(Map json) :
    property = json['property'],
    min = json['min'] ?? double.negativeInfinity,
    max = json['max'] ?? double.infinity;
}

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
      json['icon'],
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



