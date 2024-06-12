/// The only item category a productivity bonus will apply to
const intermediateProductsCategory = "intermediate-products";

/// This object contains the full graph of relevant objects
/// It will fully manage all M-M relationships between recipes, items, machines, etc
/// All items have an "id" field
/// This is used internally by the db and application
/// It has no relation to anything within Factorio itself
class ItemContext {
  /// Represents game version
  final String gameVersion;

  /// List of applied mods
  final Set<String> mods;

  late final Set<Item> items;
  late final Set<Recipe> recipes;
  late final Set<CraftingMachine> machines;
  late final Set<Module> modules;
  late final Set<Beacon> beacons;
  late final Set<Belt> belts;

  /// Contains all products generated by placing an item in the rocket cargo
  late final Map<Item, Map<Item, int>> rocketProducts;

  /// Number of rocket parts required for rocket in this game version and mod set
  late final Item rocketPart;
  late final int rocketPartsRequired;

  ItemContext.unpopulated(
      {required this.gameVersion, Set<String> mods = const {}})
      : mods = Set.unmodifiable(mods);

  ItemContext.fromDatabase(
      {required this.gameVersion, Set<String> mods = const {}})
      : mods = Set.unmodifiable(mods) {
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
  late final Set<Recipe> producedBy = Set.unmodifiable(
      context.recipes.where((recipe) => recipe.products.containsKey(this)));

  /// List of recipes this item is consumed by
  late final Set<Recipe> consumedBy = Set.unmodifiable(
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

  /// Controls what machiness can craft this recipe
  final String recipeCategory;

  /// Contains a full list of machiness that can craft this recipe
  late final Set<CraftingMachine> validMachines = Set.unmodifiable(context
      .machines
      .where((machine) => machine.recipeCategories.contains(recipeCategory)));

  Recipe(
      {required this.context,
      required this.id,
      required this.name,
      required Map<Item, double> ingredients,
      required Map<Item, double> products,
      required this.time,
      required this.recipeCategory})
      : ingredients = Map.unmodifiable(ingredients),
        products = Map.unmodifiable(products);
}

/// Represents possible module effects
enum CraftingEffect { speed, productivity, powerConsumption, pollution }

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
          CraftingEffect.powerConsumption: consumptionBonus,
          CraftingEffect.pollution: pollutionBonus
        }..removeWhere((effect, value) => value == 0));

  String get name => item.name;
}

/// Represents a crafting machine
class CraftingMachine {
  final ItemContext context;

  final String id;
  final Item item;

  final int moduleSlots;

  /// Given in watts
  final int powerConsumption;

  /// Given in watts
  final int powerDrain;
  final bool isBurner;
  final double pollutionPerMinute;

  /// Specifies what module effects can be applied to this machine
  final Set<CraftingEffect> allowedEffects;

  /// Full list of recipe categories this machine can craft
  final Set<String> recipeCategories;

  /// Base speed multiplier
  final double baseSpeed;

  /// Valid modules based upon allowedEffects
  late final Set<Module> allowedModules = Set.unmodifiable(context.modules
      .where((module) => module.effects.keys
          .every((effect) => allowedEffects.contains(effect))));

  CraftingMachine(
      {required this.context,
      required this.id,
      required this.item,
      required this.powerConsumption,
      required this.powerDrain,
      this.isBurner = false,
      required this.pollutionPerMinute,
      required List<String> recipeCategories,
      this.baseSpeed = 1.0,
      required this.moduleSlots,
      required List<CraftingEffect> allowedEffects})
      : recipeCategories = Set.unmodifiable(recipeCategories),
        allowedEffects = Set.unmodifiable(allowedEffects);

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
  final Set<CraftingEffect> allowedEffects;

  /// Valid modules based upon allowedEffects
  late final Set<Module> allowedModules = Set.unmodifiable(context.modules
      .where((module) => module.effects.keys
          .every((effect) => allowedEffects.contains(effect))));

  Beacon(
      {required this.context,
      required this.id,
      required this.item,
      required this.distributionEffectivity,
      required List<CraftingEffect> allowedEffects})
      : allowedEffects = Set.unmodifiable(allowedEffects);

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
