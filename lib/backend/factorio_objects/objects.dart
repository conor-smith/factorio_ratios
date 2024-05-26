/// The only item category a productivity bonus will apply to
const intermediateProductsCategory = "intermediate-products";

/// This object contains the full graph of relevant objects
/// It will fully manage all M-M relationships between recipes, items, buildings, etc
/// All items have an "id" field
/// This is used internally by the db and application
/// It has no relation to anything within Factorio itself
class ItemContext {
  /// Represents game version
  final String gameVersion;

  /// List of applied mods
  final List<String> mods;

  late final List<Item> items;
  late final List<Recipe> recipes;
  late final List<CraftingBuilding> buildings;
  late final List<Module> modules;
  late final List<Beacon> beacons;
  late final List<Belt> belts;

  /// Contains all products generated by placing an item in the rocket cargo
  late final Map<Item, Map<Item, int>> rocketProducts;

  /// Number of rocket parts required for rocket in this game version and mod set
  late final int rocketPartsRequired;

  ItemContext.unpopulated({required this.gameVersion, this.mods = const []});

  ItemContext.fromDatabase({required this.gameVersion, this.mods = const []}) {
    // TODO
    throw UnimplementedError();
  }
}

/// Represents a factorio item
class Item {
  final ItemContext context;

  final String id;
  final String name;

  /// Used by ratio graph to supply number of belts required to transport this item
  /// If true, does not use belts
  final bool isFluid;

  /// Places item within GUIs
  /// Will apply productivity bonus if category is intermediate
  final String category;

  /// List of recipes this item can be produced by
  late final List<Recipe> producedBy = List.unmodifiable(
      context.recipes.where((recipe) => recipe.products.containsKey(this)));

  /// List of recipes this item is consumed by
  late final List<Recipe> consumedBy = List.unmodifiable(
      context.recipes.where((recipe) => recipe.ingredients.containsKey(this)));

  /// Items produced when this item is placed in a rocket
  late final Map<Item, int>? rocketProducts = context.rocketProducts[this];

  Item(
      {required this.context,
      required this.id,
      required this.name,
      this.isFluid = false,
      required this.category});
}

/// Represents a factorio recipe
class Recipe {
  final ItemContext context;

  final String id;
  final String name;

  /// Represents recipe input
  final Map<Item, double> ingredients;

  /// Represents recipe output
  /// Products with a % chance of being produced must be given decimal values
  /// Eg. Uranium processing has a 99.3% chance of producing U-238, and a 0.7% chance of producing U-235
  /// As such, it's products must be {U-238: 0.993, U-235: 0.007}
  final Map<Item, double> products;

  /// Time taken for the recipe to complete at crafting speed 1
  final double time;

  /// Controls what buildings can craft this recipe
  final String recipeCategory;

  /// Contains a full list of buildings that can craft this recipe
  late final List<CraftingBuilding> validBuildings = List.unmodifiable(context
      .buildings
      .where((building) => building.recipeCategories.contains(recipeCategory)));

  Recipe(
      {required this.context,
      required this.id,
      required this.name,
      required Map<Item, int> ingredients,
      required Map<Item, double> products,
      required this.time,
      required this.recipeCategory})
      : ingredients = Map.unmodifiable(ingredients),
        products = Map.unmodifiable(products);
}

/// Represents possible module effects
enum CraftingEffect { speed, productivity, consumption, pollution }

/// Represents a factorio module
/// Bonuses are represented as doubles within effects map
/// Eg. Speed bonus of -50% = -0.5
class Module {
  final ItemContext context;

  final String id;
  final Item item;
  final Map<CraftingEffect, double> effects;

  Module(
      {required this.context,
      required this.id,
      required this.item,
      double speedBonus = 0.0,
      double consumptionBonus = 0.0,
      double productivityBonus = 0.0,
      double pollutionBonus = 0.0})
      : effects = Map.unmodifiable({
          CraftingEffect.speed: speedBonus,
          CraftingEffect.productivity: productivityBonus,
          CraftingEffect.consumption: consumptionBonus,
          CraftingEffect.pollution: pollutionBonus
        }..removeWhere((effect, value) => value == 0));

  String get name => item.name;
}

/// Represents a crafting building
class CraftingBuilding {
  final ItemContext context;

  final String id;
  final Item item;
  final int moduleSlots;

  /// Specifies what module effects can be applied to this building
  final List<CraftingEffect> allowedEffects;

  /// Full list of recipe categories this building can craft
  final List<String> recipeCategories;

  /// Base speed multiplier
  final double baseSpeed;

  /// Valid modules based upon allowedEffects
  late final List<Module> allowedModules = List.unmodifiable(context.modules
      .where((module) => module.effects.keys
          .every((effect) => allowedEffects.contains(effect))));

  CraftingBuilding(
      {required this.context,
      required this.id,
      required this.item,
      required List<String> recipeCategories,
      this.baseSpeed = 1.0,
      required this.moduleSlots,
      required List<CraftingEffect> allowedEffects})
      : recipeCategories = List.unmodifiable(recipeCategories),
        allowedEffects = List.unmodifiable(allowedEffects);

  bool canCraftRecipe(Recipe recipe) =>
      recipeCategories.contains(recipe.recipeCategory);

  String get name => item.name;
}

/// Represents beacons, both from base game and mods
class Beacon {
  final ItemContext context;

  final String id;
  final Item item;

  /// Represents the effective power of applied modules
  /// Eg. Base game beacon = 0.5
  final double distributionEffectivity;

  /// Specifies what module effects can be applied to beacon
  final List<CraftingEffect> allowedEffects;

  /// Valid modules based upon allowedEffects
  late final List<Module> allowedModules = List.unmodifiable(context.modules
      .where((module) => module.effects.keys
          .every((effect) => allowedEffects.contains(effect))));

  Beacon(
      {required this.context,
      required this.id,
      required this.item,
      required this.distributionEffectivity,
      required List<CraftingEffect> allowedEffects})
      : allowedEffects = List.unmodifiable(allowedEffects);

  String get name => item.name;
}

/// Represents a belt item
class Belt {
  final ItemContext context;

  final String id;
  final Item item;
  final double throughput;

  Belt(
      {required this.context,
      required this.id,
      required this.item,
      required this.throughput});

  String get name => item.name;
}
