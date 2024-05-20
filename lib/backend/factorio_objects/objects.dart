// TODO: Should I add error checking to the constructors of these classes?

/// The only item category a productivity bonus will apply to
const intermediateProducts = "Intermediate Products";

/// Represents the four possible effects a beacon may have
const moduleEffects = ["speed", "consumption", "productivity", "pollution"];

/// This object contains the full graph of relevant objects
/// It will fully create all M-M relationships between recipes, items, buildings, etc
class ItemContext {
  /// List of applied mods
  final List<String> mods;

  final List<Item> items;
  final List<Recipe> recipes;
  final List<CraftingBuilding> buildings;
  final List<Module> modules;
  final List<Beacon> beacons;
  final List<Belt> belts;

  ItemContext._(
      {required List<String> mods,
      required List<Item> items,
      required List<Item> recipes,
      required List<CraftingBuilding> buildings,
      required List<Module> modules,
      required List<Beacon> beacons,
      required List<Belt> belts,
      required Map<Item, MapEntry<Item, double>> rocketLaunchProducts})
      : mods = List.unmodifiable(mods),
        items = List.unmodifiable(items),
        recipes = List.unmodifiable(recipes),
        buildings = List.unmodifiable(buildings),
        modules = List.unmodifiable(modules),
        beacons = List.unmodifiable(beacons),
        belts = List.unmodifiable(belts);

  factory ItemContext([List<String> mods = const []]) {
    // TODO
    throw UnimplementedError();
  }
}

/// Represents a factorio item
class Item {
  final String id;
  final String name;

  /// Used by ratio graph to supply number of belts required to transport this item
  /// If true, does not use belts
  final bool isFluid;

  /// Places item within GUIs
  /// Will apply productivity bonus if category is intermediate
  final String category;

  /// Populated by ItemContext during build
  late final List<Recipe> producedBy;

  /// Populated by ItemContext during build
  late final List<Recipe> consumedBy;

  Item(
      {required this.id,
      required this.name,
      required this.isFluid,
      required this.category});

  set producedBy(List<Recipe> producedBy) {
    this.producedBy = List.unmodifiable(producedBy);
  }

  set consumedBy(List<Recipe> consumedBy) {
    this.consumedBy = List.unmodifiable(consumedBy);
  }
}

/// Represents a crafting building
class CraftingBuilding {
  final String id;
  final Item item;
  final int moduleSlots;

  /// Full list of recipe categories this building can craft
  final List<String> recipeCategories;

  /// Base speed multiplier
  /// Defaults to 1.0
  final double baseSpeed;

  /// Map of items produced by placing this item in the rocket
  /// Null if returns nothing
  late final Map<Item, double> rocketProducts;

  CraftingBuilding(
      {required this.id,
      required this.item,
      required List<String> recipeCategories,
      this.baseSpeed = 1.0,
      required this.moduleSlots})
      : recipeCategories = List.unmodifiable(recipeCategories);

  bool canCraftRecipe(Recipe recipe) =>
      recipeCategories.contains(recipe.recipeCategory);

  String get name => item.name;

  set rocketProducts(Map<Item, double>? rocketProducts) {
    if (rocketProducts != null) {
      this.rocketProducts = Map.unmodifiable(rocketProducts);
    } else {
      this.rocketProducts = null;
    }
  }
}

/// Represents a factorio recipe
class Recipe {
  final String id;
  final String name;
  final Map<Item, double> ingredients;

  /// Products with a % chance of being produced must be given decimal values
  /// Eg. Uranium processing has a 99.3% chance of producing U-238, and a 0.7% chance of producing U-235
  /// As such, it's products must be {U-238: 0.993, U-235: 0.007}
  final Map<Item, double> products;

  /// Time taken for the recipe to complete
  final double time;

  /// Controls what buildings can craft this recipe
  final String recipeCategory;

  /// Populated by itemContext during build
  /// Contains a full list of buildings that can craft this recipe
  late final List<CraftingBuilding> validBuildings;

  Recipe(
      {required this.id,
      required this.name,
      required Map<Item, int> ingredients,
      required Map<Item, double> products,
      required this.time,
      required this.recipeCategory})
      : ingredients = Map.unmodifiable(ingredients),
        products = Map.unmodifiable(products);

  set validBuildings(List<CraftingBuilding> validBuildings) {
    this.validBuildings = List.unmodifiable(validBuildings);
  }
}

/// Represents a factorio module
/// Bonuses are represented as doubles
/// Eg. Speed bonus of -50% = -0.5
class Module {
  final String id;
  final Item item;
  final double speedBonus;
  final double consumptionBonus;
  final double productivityBonus;
  final double pollutionBonus;

  Module(
      {required this.id,
      required this.item,
      this.speedBonus = 0.0,
      this.consumptionBonus = 0.0,
      this.productivityBonus = 0.0,
      this.pollutionBonus = 0.0});

  String get name => item.name;
}

/// Represents beacons, both from base game and mods
class Beacon {
  final String id;
  final Item item;

  /// Represents how many of this beacon can be applied to a single building
  /// If null, assumed to be (theoretically) infinite
  /// Eg. The base game beacon can technically be infinitely applied to buildings
  /// Practically of course, it is limited by the size of the building
  /// But there is no hard limit, so the base game beacon does not have a limit
  /// This does not account for diminishing effectiveness
  final int? buildingApplication;

  /// Represents the effective power of applied modules
  /// Eg. Base game beacon = 0.5
  final double moduleStrenth;

  /// This limitation will not apply if buildingApplication == null
  final int moduleSlots;

  /// Specifies what module effects cannot be applied to beacon
  /// Eg. If limitation == "productivity", this beacon cannot accept modules where the productivity bonus != 0
  final List<String> moduleEffectLimitations;

  Beacon(
      {required this.id,
      required this.item,
      this.buildingApplication,
      required this.moduleStrenth,
      required this.moduleSlots,
      required List<String> moduleEffectLimitations})
      : moduleEffectLimitations = List.unmodifiable(moduleEffectLimitations);

  String get name => item.name;
}

/// Represents a belt item
class Belt {
  final String id;
  final Item item;
  final double throughput;

  Belt({required this.id, required this.item, required this.throughput});

  String get name => item.name;
}
