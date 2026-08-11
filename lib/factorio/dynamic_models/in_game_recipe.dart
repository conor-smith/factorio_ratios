part of 'dynamic_models.dart';

class InGameRecipe implements Recipe, ToJson {
  final Recipe internalRecipe;
  final int quality;

  @override
  final String name;
  @override
  final List<InGameRecipeIngredient> ingredients;
  @override
  final List<InGameRecipeProduct> results;
  @override
  final Icon? icon;
  @override
  final InGameItem? mainProduct;

  factory InGameRecipe(Recipe internalRecipe, [int quality = 1]) {
    if (internalRecipe is InGameRecipe) {
      return internalRecipe;
    } else {
      return InGameRecipe._(internalRecipe, quality);
    }
  }

  InGameRecipe._(this.internalRecipe, this.quality)
    : name = internalRecipe.name + (quality == 1 ? '' : ': Q$quality'),
      icon = internalRecipe.icon?.withQuality(quality),
      mainProduct = internalRecipe.mainProduct != null
          ? InGameItem(internalRecipe.mainProduct!)
          : null,
      ingredients = List.unmodifiable(
        internalRecipe.ingredients.map(
          (ingredient) => InGameRecipeIngredient(ingredient, quality),
        ),
      ),
      results = List.unmodifiable(
        internalRecipe.results.map(
          (product) => InGameRecipeProduct(product, quality),
        ),
      );

  // Ensure that recipes of different quality are separated
  @override
  int compareTo(Prototype other) {
    if (other is InGameRecipe) {
      if (quality > other.quality) {
        return -1;
      } else if (quality < other.quality) {
        return 1;
      }
    }
    return internalRecipe.compareTo(other);
  }

  @override
  String get type => internalRecipe.type;
  @override
  bool get allowConsumption => internalRecipe.allowConsumption;
  @override
  bool get allowPollution => internalRecipe.allowPollution;
  @override
  bool get allowProductivity => internalRecipe.allowProductivity;
  @override
  bool get allowQuality => internalRecipe.allowQuality;
  @override
  bool get allowSpeed => internalRecipe.allowSpeed;
  @override
  List<String> get categories => internalRecipe.categories;
  @override
  List<CraftingMachine> get sortedCraftingMachines =>
      internalRecipe.sortedCraftingMachines;
  @override
  double get emissionsMultiplier => internalRecipe.emissionsMultiplier;
  @override
  bool get enabled => internalRecipe.enabled;
  @override
  double get energyRequired => internalRecipe.energyRequired;
  @override
  FactorioDatabase get factorioDb => internalRecipe.factorioDb;
  @override
  String get localisedName => internalRecipe.localisedName;
  @override
  double get maximumProductivity => internalRecipe.maximumProductivity;
  @override
  String get order => internalRecipe.order;
  @override
  ItemSubgroup? get subgroup => internalRecipe.subgroup;
  @override
  List<SurfaceCondition> get surfaceConditions =>
      internalRecipe.surfaceConditions;
  @override
  List<Surface> get surfaces => internalRecipe.surfaces;
  @override
  bool get isSimple => internalRecipe.isSimple;

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is InGameRecipe &&
          internalRecipe == other.internalRecipe &&
          quality == other.quality;

  @override
  int get hashCode => internalRecipe.hashCode + quality;

  @override
  String toString() => name;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class InGameRecipeIngredient implements RecipeIngredient {
  final RecipeIngredient internalRecipeIngredient;
  final int quality;

  @override
  final InGameItem item;

  InGameRecipeIngredient(this.internalRecipeIngredient, this.quality)
    : item = InGameItem(
        internalRecipeIngredient.item,
        quality: quality,
        temperature:
            internalRecipeIngredient.temperature ??
            internalRecipeIngredient.minimumTemperature,
      );

  @override
  FactorioDatabase get factorioDb => internalRecipeIngredient.factorioDb;
  @override
  double get amount => internalRecipeIngredient.amount;
  @override
  double? get maximumTemperature => internalRecipeIngredient.maximumTemperature;
  @override
  double? get minimumTemperature => internalRecipeIngredient.minimumTemperature;
  @override
  double? get temperature => internalRecipeIngredient.temperature;
  @override
  String get type => internalRecipeIngredient.type;

  bool matches(InGameItem item) {
    if (item is InGameSolidItem) {
      return item.internalItem == item && item.quality == quality;
    } else {
      item = item as InGameFluidItem;

      return item.internalItem == item && temperature != null
          ? item.temperature == temperature!
          : item.temperature >= minimumTemperature! &&
                item.temperature <= maximumTemperature!;
    }
  }

  @override
  // TODO: implement qualityChange
  int get qualityChange => throw UnimplementedError();

  @override
  // TODO: implement qualityMax
  int? get qualityMax => throw UnimplementedError();

  @override
  // TODO: implement qualityMin
  int? get qualityMin => throw UnimplementedError();

  @override
  // TODO: implement spoilWeight
  double get spoilWeight => throw UnimplementedError();
}

class InGameRecipeProduct implements RecipeProduct {
  @override
  final InGameItem item;
  final RecipeProduct internalRecipeProduct;

  InGameRecipeProduct(this.internalRecipeProduct, int quality)
    : item = InGameItem(
        internalRecipeProduct.item,
        quality: quality,
        temperature: internalRecipeProduct.temperature,
      );

  @override
  double? get amount => internalRecipeProduct.amount;
  @override
  double? get amountMax => internalRecipeProduct.amountMax;
  @override
  double? get amountMin => internalRecipeProduct.amountMin;
  @override
  double get extraCountFraction => internalRecipeProduct.extraCountFraction;
  @override
  FactorioDatabase get factorioDb => internalRecipeProduct.factorioDb;
  @override
  double get ignoredByProductivity =>
      internalRecipeProduct.ignoredByProductivity;
  @override
  double get percentSpoiled => internalRecipeProduct.percentSpoiled;
  @override
  double get probability => internalRecipeProduct.probability;
  @override
  double? get temperature => internalRecipeProduct.temperature;
  @override
  String get type => internalRecipeProduct.type;

  @override
  // TODO: implement affectedByQuality
  bool get affectedByQuality => throw UnimplementedError();

  @override
  // TODO: implement alwaysFresh
  bool get alwaysFresh => throw UnimplementedError();

  @override
  // TODO: implement qualityChange
  int get qualityChange => throw UnimplementedError();

  @override
  // TODO: implement qualityMax
  int? get qualityMax => throw UnimplementedError();

  @override
  // TODO: implement qualityMin
  int? get qualityMin => throw UnimplementedError();
}
