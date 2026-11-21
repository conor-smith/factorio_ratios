part of 'data_dump.dart';

class DDQuality extends DDPrototypeWithIcon {
  static const String defaultName = 'normal';

  final bool drawSpriteByDefault;
  final int level;

  final String? next;
  final double nextProbability;
  final double chainProbability;

  final double previousProbability;
  final double previousChainProbability;

  final double sciencePackDrainMultiplier;
  final double defaultMultiplier;
  final double insterterSpeedMultiplier;
  final double fluidWagonCapacityMultiplier;
  final double inventorySizeMultiplier;
  final double cargoWagonInventorySizeMultiplier;
  final double labResearchSpeedMultiplier;
  final double craftingMachineSpeedMultiplier;
  final double craftingMachineEnergyUsageMultiplier;
  final double scienceCapacityMultiplier;
  final double moduleConsumptionMultipler;
  final double moduleSpeedMultiplier;
  final double moduleProductivityMultiplier;
  final double modulePollutionMultiplier;
  final double moduleQualityMultiplier;
  final double spoilTicksMultiplier;

  final int craftingMachineModuleSlotBonus;
  final int miningDrillModuleSlotsBonus;
  final int labModuleSlotsBonus;

  // defaultMultiplier does have a default value
  // but given how many other fields depend on it, best to calculate it first
  DDQuality._({
    required super.name,
    required super.type,
    required super.localisedName,
    required super.order,
    required super.icon,
    required super.subgroupName,
    required this.drawSpriteByDefault,
    required this.level,
    required this.next,
    required double? nextProbability,
    required double? chainProbability,
    required double? previousProbability,
    required double? previousChainProbability,
    required double? sciencePackDrainMultiplier,
    required this.defaultMultiplier,
    required double? inserterSpeedMultiplier,
    required double? fluidWagonCapacityMultiplier,
    required double? inventorySizeMultiplier,
    required double? cargoWagonInventorySizeMutliplier,
    required double? labResearchSpeedMultiplier,
    required double? craftingMachineSpeedMultiplier,
    required double? craftingMachineEnergyUsageMultiplier,
    required double? toolDurabilityMultiplier,
    required double? scienceCapacityMultiplier,
    required double? moduleConsumptionMultiplier,
    required double? moduleSpeedMultiplier,
    required double? moduleProductivityMultiplier,
    required double? modulePollutionMultiplier,
    required double? moduleQualityMultiplier,
    required double? spoilTicksMultiplier,
    required int? craftingMachineModuleSlotBonus,
    required int? miningDrillModuleSlotBonus,
    required int? labModuleSlotBonus,
  }) : nextProbability = nextProbability ?? 0,
       chainProbability = ((nextProbability ?? 0.0) * 0.1)
           .clamp(0, 1)
           .toDouble(),
       previousProbability = previousProbability ?? 0,
       previousChainProbability = ((previousProbability ?? 0) * 0.1)
           .clamp(0, 1)
           .toDouble(),
       sciencePackDrainMultiplier = sciencePackDrainMultiplier ?? 1,
       insterterSpeedMultiplier = inserterSpeedMultiplier ?? defaultMultiplier,
       fluidWagonCapacityMultiplier =
           fluidWagonCapacityMultiplier ?? defaultMultiplier,
       inventorySizeMultiplier = inventorySizeMultiplier ?? defaultMultiplier,
       cargoWagonInventorySizeMultiplier =
           cargoWagonInventorySizeMutliplier ?? defaultMultiplier,
       labResearchSpeedMultiplier =
           labResearchSpeedMultiplier ?? defaultMultiplier,
       craftingMachineSpeedMultiplier =
           craftingMachineSpeedMultiplier ?? defaultMultiplier,
       craftingMachineEnergyUsageMultiplier =
           craftingMachineEnergyUsageMultiplier ?? 1,
       scienceCapacityMultiplier =
           scienceCapacityMultiplier ?? toolDurabilityMultiplier ?? 1.0 + level,
       moduleConsumptionMultipler =
           moduleConsumptionMultiplier ?? defaultMultiplier,
       moduleSpeedMultiplier = moduleSpeedMultiplier ?? defaultMultiplier,
       moduleProductivityMultiplier =
           moduleProductivityMultiplier ?? defaultMultiplier,
       modulePollutionMultiplier =
           modulePollutionMultiplier ?? defaultMultiplier,
       moduleQualityMultiplier = moduleQualityMultiplier ?? defaultMultiplier,
       spoilTicksMultiplier = spoilTicksMultiplier ?? defaultMultiplier,
       craftingMachineModuleSlotBonus = craftingMachineModuleSlotBonus ?? level,
       miningDrillModuleSlotsBonus = miningDrillModuleSlotBonus ?? level,
       labModuleSlotsBonus = labModuleSlotBonus ?? level;

  factory DDQuality.fromJson(Map json) {
    int level = json['level'];
    var defaultMultiplier =
        json['default_multiplier']?.toDouble() ?? 1.0 + (0.3 * level);

    return DDQuality._(
      name: json['name'],
      type: json['type'],
      localisedName: json['name'],
      order: json['order'],
      icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
      subgroupName: json['subgroup'],
      drawSpriteByDefault: json['draw_sprite_by_default'] ?? true,
      level: level,
      next: json['next'],
      nextProbability: json['next_probability']?.toDouble(),
      chainProbability: json['chain_probability']?.toDouble(),
      previousProbability: json['previous_probability']?.toDouble(),
      previousChainProbability: json['previous_chain_probability']?.toDouble(),
      sciencePackDrainMultiplier: json['science_pack_drain_multiplier']
          ?.toDouble(),
      defaultMultiplier: defaultMultiplier,
      inserterSpeedMultiplier: json['inserter_speed_multiplier']?.toDouble(),
      fluidWagonCapacityMultiplier: json['fluid_wagon_capacity_multiplier']
          ?.toDouble(),
      inventorySizeMultiplier: json['inventory_size_multiplier']?.toDouble(),
      cargoWagonInventorySizeMutliplier:
          json['cargo_wagon_inventory_size_multiplier']?.toDouble(),
      labResearchSpeedMultiplier: json['lab_research_speed_multiplier']
          ?.toDouble(),
      craftingMachineSpeedMultiplier: json['crafting_machine_speed_multiplier']
          ?.toDouble(),
      craftingMachineEnergyUsageMultiplier:
          json['crafting_machine_energy_usage_multiplier']?.toDouble(),
      toolDurabilityMultiplier: json['tool_durability_multiplier']?.toDouble(),
      scienceCapacityMultiplier: json['science_capacity_multiplier']
          ?.toDouble(),
      moduleConsumptionMultiplier: json['module_consumption_multiplier']
          ?.toDouble(),
      moduleSpeedMultiplier: json['module_speed_multiplier']?.toDouble(),
      moduleProductivityMultiplier: json['module_productivity_multiplier']
          ?.toDouble(),
      modulePollutionMultiplier: json['module_pollution_multiplier']
          ?.toDouble(),
      moduleQualityMultiplier: json['module_quality_multiplier']?.toDouble(),
      spoilTicksMultiplier: json['spoil_ticks_multiplier']?.toDouble(),
      craftingMachineModuleSlotBonus:
          json['crafting_machine_module_slots_bonus'],
      miningDrillModuleSlotBonus: json['mining_drill_module_slot_bonus'],
      labModuleSlotBonus: json['lab_module_slots_bonus'],
    );
  }
}
