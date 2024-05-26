import 'package:factorio_ratios/backend/factorio_objects/objects.dart';

final ItemContext testContext = _initialiseContext();

const String logisticsCategory = "logistics";
const String productionCategory = "production";
const String intermediateCategory = intermediateProductsCategory;

const String recipeCategory = "recipe-cat-1";
const String exclusiveRecipeCategory = "recipe-cat-2";

late final Item speedModuleItem;
late final Item productivityModuleItem;
late final Item efficiencyModuleItem;

late final Module speedModule;
late final Module productivityModule;
late final Module efficiencyModule;

late final Item craftingBuilding0SlotsLowSpeedItem;
late final Item craftingBuildingExclusive2SlotsNormalSpeedItem;
late final Item craftingBuildingAllowedEffects4SlotsHighSPeedItem;

late final CraftingBuilding craftingBuilding0SlotsLowSpeed;
late final CraftingBuilding craftingBuildingExclusive2SlotsNormalSPeed;
late final CraftingBuilding craftingBuildingAllowedEffects4SlotsHighSpeed;

late final Item beaconItem;
late final Item beaconAllowedEffectsItem;
late final Item beaconDistributionEffectivityItem;

late final Beacon beacon;
late final Beacon beaconAllowedEffects;
late final Beacon beaconDistributionEffectivity;

ItemContext _initialiseContext() {
  var context = ItemContext.unpopulated(gameVersion: "test");

  speedModuleItem = Item(
      context: context,
      id: _createId(),
      name: "speed module",
      category: productionCategory);
  productivityModuleItem = Item(
      context: context,
      id: _createId(),
      name: "productivity module",
      category: productionCategory);
  efficiencyModuleItem = Item(
      context: context,
      id: _createId(),
      name: "efficiency module",
      category: productionCategory);

  speedModule = Module(
      context: context,
      id: _createId(),
      item: speedModuleItem,
      speedBonus: 0.5,
      consumptionBonus: 0.7);
  productivityModule = Module(
      context: context,
      id: _createId(),
      item: productivityModuleItem,
      speedBonus: -0.15,
      productivityBonus: 0.1,
      consumptionBonus: 0.8,
      pollutionBonus: 0.1);
  efficiencyModule = Module(
      context: context,
      id: _createId(),
      item: efficiencyModuleItem,
      consumptionBonus: -0.5);

  craftingBuilding0SlotsLowSpeedItem = Item(
      context: context,
      id: _createId(),
      name: "crafting building",
      category: productionCategory);
  craftingBuildingExclusive2SlotsNormalSpeedItem = Item(
      context: context,
      id: _createId(),
      name: "exclusive crafting building",
      category: productionCategory);
  craftingBuildingAllowedEffects4SlotsHighSPeedItem = Item(
      context: context,
      id: _createId(),
      name: "allowed effects crafting building",
      category: productionCategory);

  craftingBuilding0SlotsLowSpeed = CraftingBuilding(
      context: context,
      id: _createId(),
      item: craftingBuilding0SlotsLowSpeedItem,
      recipeCategories: const [recipeCategory],
      baseSpeed: 0.7,
      moduleSlots: 0,
      allowedEffects: CraftingEffect.values);
  craftingBuildingExclusive2SlotsNormalSPeed = CraftingBuilding(
      context: context,
      id: _createId(),
      item: craftingBuildingExclusive2SlotsNormalSpeedItem,
      recipeCategories: [exclusiveRecipeCategory, recipeCategory],
      baseSpeed: 1.0,
      moduleSlots: 2,
      allowedEffects: CraftingEffect.values);
  craftingBuildingAllowedEffects4SlotsHighSpeed = CraftingBuilding(
      context: context,
      id: _createId(),
      item: craftingBuildingAllowedEffects4SlotsHighSPeedItem,
      recipeCategories: [recipeCategory],
      baseSpeed: 1.2,
      moduleSlots: 4,
      allowedEffects: const [CraftingEffect.speed, CraftingEffect.consumption]);

  beaconItem = Item(
      context: context,
      id: _createId(),
      name: "beacon",
      category: productionCategory);
  beaconAllowedEffectsItem = Item(
      context: context,
      id: _createId(),
      name: "beacon allowed effects",
      category: productionCategory);
  beaconDistributionEffectivityItem = Item(
      context: context,
      id: _createId(),
      name: "beacon distribution effectivity",
      category: productionCategory);

  beacon = Beacon(
      context: context,
      id: _createId(),
      item: beaconItem,
      distributionEffectivity: 1,
      allowedEffects: CraftingEffect.values);
  beaconAllowedEffects = Beacon(
      context: context,
      id: _createId(),
      item: beaconAllowedEffectsItem,
      distributionEffectivity: 1,
      allowedEffects: const [CraftingEffect.consumption]);
  beaconDistributionEffectivity = Beacon(
      context: context,
      id: _createId(),
      item: beaconDistributionEffectivityItem,
      distributionEffectivity: 0.5,
      allowedEffects: CraftingEffect.values);

  var itemsList = [
    speedModuleItem,
    productivityModuleItem,
    efficiencyModuleItem,
    craftingBuilding0SlotsLowSpeedItem,
    craftingBuildingExclusive2SlotsNormalSpeedItem,
    craftingBuildingAllowedEffects4SlotsHighSPeedItem,
    beaconItem,
    beaconAllowedEffectsItem,
    beaconDistributionEffectivityItem
  ];

  var buildingsList = [
    craftingBuilding0SlotsLowSpeed,
    craftingBuildingExclusive2SlotsNormalSPeed,
    craftingBuildingAllowedEffects4SlotsHighSpeed
  ];

  var beaconList = [
    beacon,
    beaconAllowedEffects,
    beaconDistributionEffectivity
  ];

  context.items = itemsList;
  context.buildings = buildingsList;
  context.beacons = beaconList;

  return context;
}

int _idToIncrement = 0;
String _createId() {
  _idToIncrement++;
  return _idToIncrement.toString();
}
