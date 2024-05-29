import 'package:factorio_ratios/backend/factorio_objects/objects.dart';

late final ItemContext testContext;

const String logisticsCategory = "logistics";
const String productionCategory = "production";
const String intermediateCategory = intermediateProductsCategory;

const String defaultRecipeCategory = "recipe-cat-1";
const String exclusiveRecipeCategory = "recipe-cat-2";
const String rocketPartCategory = "rocket-part-cat";

late final Item speedModuleItem;
late final Item productivityModuleItem;
late final Item efficiencyModuleItem;
late final Item impossibleModuleItem;

late final Module speedModule;
late final Module productivityModule;
late final Module efficiencyModule;
late final Module impossibleModule;

late final Item craftingBuilding0SlotsLowSpeedItem;
late final Item craftingBuildingExclusive2SlotsNormalSpeedItem;
late final Item craftingBuildingAllowedEffects4SlotsHighSpeedItem;
late final Item rocketSiloItem;

late final CraftingBuilding craftingBuilding0SlotsLowSpeed;
late final CraftingBuilding craftingBuildingExclusive2SlotsNormalSpeed;
late final CraftingBuilding craftingBuildingAllowedEffects4SlotsHighSpeed;
late final CraftingBuilding rocketSilo;

late final Item beaconDefaultItem;
late final Item beaconAllowedEffectsItem;
late final Item beaconDistributionEffectivityItem;

late final Beacon beaconDefault;
late final Beacon beaconAllowedEffects;
late final Beacon beaconDistributionEffectivity;

// Recipe tree looks like this
// Final output is rocket science
// Balancer has only 2 outputs
//
//    +
//    |
//  +-+------+
//  | Rocket |
//  +-+----+-+
//    |    |
//    |    o---------o
//    |              |
//  +-+------+    +--+--------+
//  | Rocket |    | Satellite |
//  |  part  |    +------+-+--+
//  +-+-+--+-+           | |
//    | |  |             | |
//    | |  o----------o  | |
//    | o--o          |  | o--o
//    |    |          |  |    |
//    |  +-+----+   +-+--+-+  |
//    |  | dep1 |   | dep2 |  |
//    |  +-+--+-+   +----+-+  |
//    |    |  |          |    |
//    |    |  o-------o  |    |
//    |    |          |  |    |
//    |    | o--------+--+----o
//    |    | |        |  |
//    |  +-+-+--+   +-+--+-+
//    |  | dep3 |   | dep4 |
//    |  +-+-+--+   +-+--+-+
//    |    | |        |  |
//    |  o-o |        |  |
//    |  | o-o        |  |
//    |  | | o--------+  |
//    |  | | |           |
//  +-+--+-+-+-+         |
//  | balancer |         |
//  +-+--------+         |
//    |                  |
//    |      o-----------o
//    |      |
//  +-+------+-+
//  | resource |
//  +----------+

late final Item rocketScience;
late final Item rocketPart;
late final Item satellite;
late final Item dep1NonIntermediate;
late final Item dep2;
late final Item dep3;
late final Item dep4;
late final Item heavyOil;
late final Item lightOil;
late final Item petroleum;
late final Item coal;

late final Recipe recipeRocketPart;
late final Recipe recipeSatellite;
late final Recipe recipeDep1;
late final Recipe recipeDep2Exclusive;
late final Recipe recipeDep3;
late final Recipe recipeDep4Cyclical;
late final Recipe recipeCoalLiquefaction;
late final Recipe recipeHeavyOilCracking;
late final Recipe recipeLightOilCracking;

bool _initialized = false;

void initialiseTestContext() {
  if (!_initialized) {
    _initialized = true;
    testContext = ItemContext.unpopulated(gameVersion: "test");

    var modules = _createModules();
    var buildings = _createBuildings();
    var beacons = _createBeacons();
    var recipes = _createRecipes();
    var rocketOutput = {
      satellite: {rocketScience: 12},
      beaconDefaultItem: {rocketSiloItem: 1}
    };

    var allItems = <Item>{}
      ..addAll(modules.map((module) => module.item))
      ..addAll(buildings.map((building) => building.item))
      ..addAll(beacons.map((beacon) => beacon.item))
      ..addAll(recipes
          .map((recipe) => List<Item>.from(recipe.ingredients.keys)
            ..addAll(recipe.products.keys))
          .reduce((items1, items2) => items1..addAll(items2)))
      ..addAll(rocketOutput.values
          .map((outputs) => List<Item>.from(outputs.keys))
          .reduce((outputs1, outputs2) => outputs1..addAll(outputs2)));

    testContext.items = allItems;
    testContext.modules = modules;
    testContext.buildings = buildings;
    testContext.beacons = beacons;
    testContext.rocketPart = rocketPart;
    testContext.rocketPartsRequired = 100;
    testContext.rocketProducts = rocketOutput;
  }
}

Set<Module> _createModules() {
  speedModuleItem = Item(
      context: testContext,
      id: _createId(),
      name: "speed module",
      category: productionCategory);
  productivityModuleItem = Item(
      context: testContext,
      id: _createId(),
      name: "productivity module",
      category: productionCategory);
  efficiencyModuleItem = Item(
      context: testContext,
      id: _createId(),
      name: "efficiency module",
      category: productionCategory);
  impossibleModuleItem = Item(
      context: testContext,
      id: _createId(),
      name: "impossible module",
      category: productionCategory);

  speedModule = Module(
      context: testContext,
      id: _createId(),
      item: speedModuleItem,
      speedBonus: 0.5,
      consumptionBonus: 0.7);
  productivityModule = Module(
      context: testContext,
      id: _createId(),
      item: productivityModuleItem,
      speedBonus: -0.15,
      productivityBonus: 0.1,
      consumptionBonus: 0.8,
      pollutionBonus: 0.1);
  efficiencyModule = Module(
      context: testContext,
      id: _createId(),
      item: efficiencyModuleItem,
      consumptionBonus: -0.5);
  impossibleModule = Module(
      context: testContext,
      id: _createId(),
      item: impossibleModuleItem,
      speedBonus: -1.0,
      productivityBonus: -1.0,
      consumptionBonus: -1.0,
      pollutionBonus: -1.0);

  return {speedModule, productivityModule, efficiencyModule, impossibleModule};
}

Set<CraftingBuilding> _createBuildings() {
  craftingBuilding0SlotsLowSpeedItem = Item(
      context: testContext,
      id: _createId(),
      name: "crafting building",
      category: productionCategory);
  craftingBuildingExclusive2SlotsNormalSpeedItem = Item(
      context: testContext,
      id: _createId(),
      name: "exclusive crafting building",
      category: productionCategory);
  craftingBuildingAllowedEffects4SlotsHighSpeedItem = Item(
      context: testContext,
      id: _createId(),
      name: "allowed effects crafting building",
      category: productionCategory);

  craftingBuilding0SlotsLowSpeed = CraftingBuilding(
      context: testContext,
      id: _createId(),
      item: craftingBuilding0SlotsLowSpeedItem,
      recipeCategories: const [defaultRecipeCategory],
      baseSpeed: 0.7,
      moduleSlots: 0,
      allowedEffects: CraftingEffect.values);
  craftingBuildingExclusive2SlotsNormalSpeed = CraftingBuilding(
      context: testContext,
      id: _createId(),
      item: craftingBuildingExclusive2SlotsNormalSpeedItem,
      recipeCategories: [exclusiveRecipeCategory, defaultRecipeCategory],
      baseSpeed: 1.0,
      moduleSlots: 2,
      allowedEffects: CraftingEffect.values);
  craftingBuildingAllowedEffects4SlotsHighSpeed = CraftingBuilding(
      context: testContext,
      id: _createId(),
      item: craftingBuildingAllowedEffects4SlotsHighSpeedItem,
      recipeCategories: [defaultRecipeCategory],
      baseSpeed: 1.2,
      moduleSlots: 4,
      allowedEffects: const [CraftingEffect.speed, CraftingEffect.consumption]);

  return {
    craftingBuilding0SlotsLowSpeed,
    craftingBuildingExclusive2SlotsNormalSpeed,
    craftingBuildingAllowedEffects4SlotsHighSpeed
  };
}

Set<Beacon> _createBeacons() {
  beaconDefaultItem = Item(
      context: testContext,
      id: _createId(),
      name: "beacon",
      category: productionCategory);
  beaconAllowedEffectsItem = Item(
      context: testContext,
      id: _createId(),
      name: "beacon allowed effects",
      category: productionCategory);
  beaconDistributionEffectivityItem = Item(
      context: testContext,
      id: _createId(),
      name: "beacon distribution effectivity",
      category: productionCategory);

  beaconDefault = Beacon(
      context: testContext,
      id: _createId(),
      item: beaconDefaultItem,
      distributionEffectivity: 1,
      allowedEffects: CraftingEffect.values);
  beaconAllowedEffects = Beacon(
      context: testContext,
      id: _createId(),
      item: beaconAllowedEffectsItem,
      distributionEffectivity: 1,
      allowedEffects: const [CraftingEffect.consumption]);
  beaconDistributionEffectivity = Beacon(
      context: testContext,
      id: _createId(),
      item: beaconDistributionEffectivityItem,
      distributionEffectivity: 0.5,
      allowedEffects: CraftingEffect.values);

  return {beaconDefault, beaconAllowedEffects, beaconDistributionEffectivity};
}

Set<Recipe> _createRecipes() {
  rocketScience = Item(
      context: testContext,
      id: _createId(),
      name: "rocket science",
      category: intermediateCategory);
  rocketPart = Item(
      context: testContext,
      id: _createId(),
      name: "rocket part",
      category: intermediateCategory);
  satellite = Item(
      context: testContext,
      id: _createId(),
      name: "satellite",
      category: productionCategory);
  dep1NonIntermediate = Item(
      context: testContext,
      id: _createId(),
      name: "dep 1",
      category: productionCategory);
  dep2 = Item(
      context: testContext,
      id: _createId(),
      name: "dep 2",
      category: intermediateCategory);
  dep3 = Item(
      context: testContext,
      id: _createId(),
      name: "dep 3",
      category: intermediateCategory);
  dep4 = Item(
      context: testContext,
      id: _createId(),
      name: "dep 4",
      category: intermediateCategory);
  heavyOil = Item(
      context: testContext,
      id: _createId(),
      name: "heavy oil",
      isFluid: true,
      category: intermediateCategory);
  lightOil = Item(
      context: testContext,
      id: _createId(),
      name: "light oil",
      isFluid: true,
      category: intermediateCategory);
  petroleum = Item(
      context: testContext,
      id: _createId(),
      name: "petroleum",
      isFluid: true,
      category: intermediateCategory);
  coal = Item(
      context: testContext,
      id: _createId(),
      name: "coal",
      category: intermediateCategory);

  recipeRocketPart = Recipe(
      context: testContext,
      id: _createId(),
      name: "rocket-part-recipe",
      ingredients: {lightOil: 16, dep1NonIntermediate: 20, dep2: 11},
      products: {rocketPart: 1},
      time: 3,
      recipeCategory: rocketPartCategory);
  recipeSatellite = Recipe(
      context: testContext,
      id: _createId(),
      name: "satellite-recipe",
      ingredients: {dep1NonIntermediate: 8, dep3: 16},
      products: {satellite: 1},
      time: 5,
      recipeCategory: exclusiveRecipeCategory);
  recipeDep1 = Recipe(
      context: testContext,
      id: _createId(),
      name: "dep-1-recipe",
      ingredients: {dep3: 14, dep4: 6},
      products: {dep1NonIntermediate: 12},
      time: 10,
      recipeCategory: defaultRecipeCategory);
  recipeDep2Exclusive = Recipe(
      context: testContext,
      id: _createId(),
      name: "dep-2-recipe",
      ingredients: {dep4: 6},
      products: {dep2: 1},
      time: 9,
      recipeCategory: exclusiveRecipeCategory);
  recipeDep3 = Recipe(
      context: testContext,
      id: _createId(),
      name: "dep-3-recipe",
      ingredients: {lightOil: 12, petroleum: 16},
      products: {dep3: 2},
      time: 0.5,
      recipeCategory: defaultRecipeCategory);
  recipeDep4Cyclical = Recipe(
      context: testContext,
      id: _createId(),
      name: "dep-4-recipe",
      ingredients: {lightOil: 14, dep4: 6},
      products: {dep4: 14},
      time: 5,
      recipeCategory: defaultRecipeCategory);
  recipeCoalLiquefaction = Recipe(
      context: testContext,
      id: _createId(),
      name: "coal-liquefaction",
      ingredients: {coal: 10, heavyOil: 20},
      products: {heavyOil: 45, lightOil: 10, petroleum: 10},
      time: 2,
      recipeCategory: defaultRecipeCategory);
  recipeHeavyOilCracking = Recipe(
      context: testContext,
      id: _createId(),
      name: "heavy-oil-cracking",
      ingredients: {heavyOil: 5},
      products: {lightOil: 10},
      time: 2,
      recipeCategory: defaultRecipeCategory);
  recipeLightOilCracking = Recipe(
      context: testContext,
      id: _createId(),
      name: "light-oil-cracking",
      ingredients: {lightOil: 5},
      products: {petroleum: 10},
      time: 2,
      recipeCategory: defaultRecipeCategory);

  return {
    recipeRocketPart,
    recipeSatellite,
    recipeDep1,
    recipeDep2Exclusive,
    recipeDep3,
    recipeDep4Cyclical,
    recipeCoalLiquefaction,
    recipeHeavyOilCracking,
    recipeLightOilCracking
  };
}

int _idToIncrement = 0;

String _createId() {
  _idToIncrement++;
  return _idToIncrement.toString();
}
