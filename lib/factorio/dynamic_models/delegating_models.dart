part of 'dynamic_models.dart';

// These classes exist for convenience and clarity
// It makes it very easy to track what exactly is changing
abstract class DelegatingPrototype implements Prototype {
  Prototype get internal;

  @override
  String get name => internal.name;
  @override
  String get type => internal.type;
  @override
  String get localisedName => internal.localisedName;
  @override
  String get order => internal.order;
  @override
  ItemSubgroup? get subgroup => internal.subgroup;

  @override
  int compareTo(Prototype other) => compareTwoQualityPrototypes(this, other);

  @override
  String toString() => name;
}

int compareTwoQualityPrototypes(Prototype prototype1, Prototype prototype2) {
  var prototypeCompare = compareTwoPrototypes(prototype1, prototype2);

  if (prototypeCompare == 0) {
    var quality1 = prototype1 is QualityPrototype
        ? prototype1.quality
        : prototype1.factorioDb.defaultQuality;
    var quality2 = prototype2 is QualityPrototype
        ? prototype2.quality
        : prototype2.factorioDb.defaultQuality;

    if (quality1 == quality2) {
      return 0;
    } else if (quality1 < quality2) {
      return -1;
    } else if (quality1 > quality2) {
      return 1;
    } else {
      // Can get here if two qualities are not on same quality chain
      return 0;
    }
  } else {
    return prototypeCompare;
  }
}

abstract class DelegatingPrototypeWithIcon extends DelegatingPrototype
    implements PrototypeWithIcon {
  @override
  PrototypeWithIcon get internal;

  @override
  Icon? get icon => internal.icon;
}

abstract class DelegatingItem extends DelegatingPrototypeWithIcon
    implements Item {
  @override
  Item get internal;

  @override
  FactorioDatabase get factorioDb => internal.factorioDb;

  @override
  double? get fuelValue => internal.fuelValue;

  @override
  bool get hidden => internal.hidden;

  @override
  List<Recipe> get consumedBy => internal.consumedBy;
  @override
  List<Recipe> get producedBy => internal.producedBy;
}

abstract class DelegatingSolidItem extends DelegatingItem implements SolidItem {
  @override
  SolidItem get internal;

  @override
  int get stackSize => internal.stackSize;
  @override
  int? get spoilTicks => internal.spoilTicks;

  @override
  String? get fuelCategory => internal.fuelCategory;
  @override
  double? get fuelEmissionsMultiplier => internal.fuelEmissionsMultiplier;

  @override
  int? get spoilQualityChange => internal.spoilQualityChange;
  @override
  Quality? get spoilQualityMin => internal.spoilQualityMin;
  @override
  Quality? get spoilQualityMax => internal.spoilQualityMax;

  @override
  Item? get spoilResult => internal.spoilResult;
  @override
  List<Item> get producedFromSpoiling => internal.producedFromSpoiling;

  @override
  Item? get burntResult => internal.burntResult;
  @override
  List<Item> get producedFromBurning => internal.producedFromBurning;
}

abstract class DelegatingFluidItem extends DelegatingItem implements FluidItem {
  @override
  FluidItem get internal;

  @override
  double get defaultTemperature => internal.defaultTemperature;
  @override
  double get heatCapacity => internal.heatCapacity;
  @override
  double get maxTemperature => internal.maxTemperature;
  @override
  double get emissionsMultiplier => internal.emissionsMultiplier;
}

abstract class DelegatingRecipe extends DelegatingPrototypeWithIcon
    implements Recipe {
  @override
  Recipe get internal;

  @override
  FactorioDatabase get factorioDb => internal.factorioDb;

  @override
  List<String> get categories => internal.categories;
  @override
  double get energyRequired => internal.energyRequired;
  @override
  double get maximumProductivity => internal.maximumProductivity;
  @override
  double get emissionsMultiplier => internal.emissionsMultiplier;

  @override
  bool get enabled => internal.enabled;
  @override
  bool get allowConsumption => internal.allowConsumption;
  @override
  bool get allowSpeed => internal.allowSpeed;
  @override
  bool get allowProductivity => internal.allowProductivity;
  @override
  bool get allowPollution => internal.allowPollution;
  @override
  bool get allowQuality => internal.allowQuality;

  @override
  List<RecipeIngredient> get ingredients => internal.ingredients;
  @override
  List<RecipeProduct> get results => internal.results;
  @override
  List<SurfaceCondition> get surfaceConditions => internal.surfaceConditions;

  @override
  Item? get mainProduct => internal.mainProduct;

  @override
  List<CraftingMachine> get sortedCraftingMachines =>
      internal.sortedCraftingMachines;
  @override
  List<Surface> get surfaces => internal.surfaces;
  @override
  bool get isSimple => internal.isSimple;
}

abstract class DelegatingRecipeIngredient implements RecipeIngredient {
  RecipeIngredient get internal;

  @override
  FactorioDatabase get factorioDb => internal.factorioDb;

  @override
  String get type => internal.type;
  @override
  Item get item => internal.item;

  @override
  double get amount => internal.amount;
  @override
  Quality? get qualityMin => internal.qualityMin;
  @override
  Quality? get qualityMax => internal.qualityMax;
  @override
  int? get qualityChange => internal.qualityChange;

  @override
  double? get spoilWeight => internal.spoilWeight;

  @override
  double? get temperature => internal.temperature;
  @override
  double? get minimumTemperature => internal.minimumTemperature;
  @override
  double? get maximumTemperature => internal.maximumTemperature;
}

abstract class DelegatingRecipeProduct implements RecipeProduct {
  RecipeProduct get internal;

  @override
  FactorioDatabase get factorioDb => internal.factorioDb;

  @override
  String get type => internal.type;
  @override
  Item get item => internal.item;

  @override
  double? get amount => internal.amount;
  @override
  double? get amountMin => internal.amountMin;
  @override
  double? get amountMax => internal.amountMax;
  @override
  double get independentProbability => internal.independentProbability;
  @override
  SharedProbability get sharedProbability => internal.sharedProbability;
  @override
  double get ignoredByProductivity => internal.ignoredByProductivity;

  @override
  double? get extraCountFraction => internal.extraCountFraction;

  @override
  double? get percentSpoiled => internal.percentSpoiled;
  @override
  bool get alwaysFresh => internal.alwaysFresh;

  @override
  Quality? get qualityMin => internal.qualityMin;
  @override
  Quality? get qualityMax => internal.qualityMax;
  @override
  int? get qualityChange => internal.qualityChange;
  @override
  bool get affectedByQuality => internal.affectedByQuality;

  @override
  double? get temperature => internal.temperature;
}

abstract class DelegatingCraftingMachine extends DelegatingPrototypeWithIcon
    implements CraftingMachine {
  @override
  CraftingMachine get internal;

  @override
  FactorioDatabase get factorioDb => internal.factorioDb;

  @override
  double get craftingSpeed => internal.craftingSpeed;
  @override
  double get energyUsage => internal.energyUsage;
  @override
  int get moduleSlots => internal.moduleSlots;

  @override
  CraftingMachineEnergySource get energySource => internal.energySource;
  @override
  EffectReceiver get effectReceiver => internal.effectReceiver;

  @override
  List<String> get craftingCategories => internal.craftingCategories;
  @override
  List<String> get allowedEffects => internal.allowedEffects;

  @override
  bool get needsSolidFuel => internal.needsSolidFuel;
  @override
  List<Item> get fuelItems => internal.fuelItems;

  @override
  Item? get item => internal.item;

  @override
  List<Recipe> get recipes => internal.recipes;
}
