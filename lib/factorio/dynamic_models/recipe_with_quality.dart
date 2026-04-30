part of 'dynamic_models.dart';

class RecipeWithQuality implements Recipe {
  final Recipe internalRecipe;
  final int quality;

  @override
  final String name;
  @override
  final List<InGameRecipeIngredient> ingredients;
  @override
  final List<InGameRecipeProduct> results;
  @override
  final List<IconData>? icons;
  @override
  final InGameItem? mainProduct;

  RecipeWithQuality(this.internalRecipe, [this.quality = 1])
    : name = internalRecipe.name + (quality == 1 ? '' : ': Q$quality'),
      icons = _verifyQualityAndUpdateIcon(internalRecipe.icons, quality),
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
  int compareTo(Ordered other) => internalRecipe.compareTo(other);
  @override
  List<CraftingMachine> get craftingMachines => internalRecipe.craftingMachines;
  @override
  double get defaultScale => internalRecipe.defaultScale;
  @override
  double get emissionsMultiplier => internalRecipe.emissionsMultiplier;
  @override
  bool get enabled => internalRecipe.enabled;
  @override
  double get energyRequired => internalRecipe.energyRequired;
  @override
  double get expectedIconSize => internalRecipe.expectedIconSize;
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
  bool operator ==(Object other) =>
      other is RecipeWithQuality &&
      internalRecipe == other.internalRecipe &&
      quality == other.quality;

  @override
  int get hashCode => internalRecipe.hashCode + quality;

  @override
  String toString() => name;
}

class InGameRecipeIngredient implements RecipeIngredient {
  final RecipeIngredient internalRecipeIngredient;
  final int quality;

  InGameRecipeIngredient(this.internalRecipeIngredient, this.quality);

  @override
  FactorioDatabase get factorioDb => internalRecipeIngredient.factorioDb;
  @override
  Item get item => internalRecipeIngredient.item;
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
    if (item is SolidItemWithQuality) {
      return item.internalItem == item && item.quality == quality;
    } else {
      item = item as FluidItemWithTemp;

      return item.internalItem == item && temperature != null
          ? item.temperature == temperature!
          : item.temperature >= minimumTemperature! &&
                item.temperature <= maximumTemperature!;
    }
  }
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
  double get temperature => internalRecipeProduct.temperature;
  @override
  String get type => internalRecipeProduct.type;
}
