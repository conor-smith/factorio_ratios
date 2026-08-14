part of 'dynamic_models.dart';

class InGameRecipe extends DelegatingRecipe
    implements QualityPrototype, ToJson {
  @override
  final Recipe internal;
  @override
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

  factory InGameRecipe(Recipe recipe, [int quality = 1]) {
    if (recipe is InGameRecipe && quality == recipe.quality) {
      return recipe;
    } else if (recipe is DelegatingRecipe) {
      recipe = recipe.internal;
    }
    return InGameRecipe._(recipe, quality);
  }

  InGameRecipe._(this.internal, this.quality)
    : name = internal.name + (quality == 1 ? '' : ': Q$quality'),
      icon = internal.icon?.withQuality(quality),
      mainProduct = internal.mainProduct != null
          ? InGameItem(internal.mainProduct!)
          : null,
      ingredients = List.unmodifiable(
        internal.ingredients.map(
          (ingredient) => InGameRecipeIngredient(ingredient, quality),
        ),
      ),
      results = List.unmodifiable(
        internal.results.map(
          (product) => InGameRecipeProduct(product, quality),
        ),
      );

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is InGameRecipe &&
          internal == other.internal &&
          quality == other.quality;

  @override
  int get hashCode => internal.hashCode + quality;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class InGameRecipeIngredient extends DelegatingRecipeIngredient {
  // TODO
  @override
  final RecipeIngredient internal;

  @override
  final ItemSpec item;

  InGameRecipeIngredient._(this.internal);

  factory InGameRecipeIngredient(
    RecipeIngredient ingredient,
    int recipeQuality,
  ) {
    int? qualityMin = ingredient.qualityMin;
    int? qualityMax = ingredient.qualityMax;
    double? minimumTemperature = ingredient.minimumTemperature;
    double? maximumTemperature = ingredient.maximumTemperature;

    if (ingredient.type == 'item') {
      if (qualityMin == null && qualityMax != null) {}
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
  double? get extraCountFraction => internalRecipeProduct.extraCountFraction;
  @override
  FactorioDatabase get factorioDb => internalRecipeProduct.factorioDb;
  @override
  double get ignoredByProductivity =>
      internalRecipeProduct.ignoredByProductivity;
  @override
  double? get percentSpoiled => internalRecipeProduct.percentSpoiled;
  @override
  double get independentProbability =>
      internalRecipeProduct.independentProbability;
  @override
  SharedProbability get sharedProbability =>
      internalRecipeProduct.sharedProbability;
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
