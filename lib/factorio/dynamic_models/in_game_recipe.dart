part of 'dynamic_models.dart';

class InGameRecipe extends DelegatingRecipe
    implements QualityPrototype, ToJson {
  @override
  final Recipe internal;
  @override
  final Quality quality;

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

  factory InGameRecipe(Recipe recipe, [Quality? quality]) {
    quality ??= recipe.factorioDb.defaultQuality;

    if (recipe is InGameRecipe && quality == recipe.quality) {
      return recipe;
    } else if (recipe is DelegatingRecipe) {
      recipe = recipe.internal;
    }
    return InGameRecipe._(recipe, quality);
  }

  InGameRecipe._(this.internal, this.quality)
    : name = quality.name != Quality.defaultName
          ? '$quality ${internal.name}'
          : internal.name,
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
    Quality recipeQuality,
  ) {
    Quality? qualityMin = ingredient.qualityMin;
    Quality? qualityMax = ingredient.qualityMax;
    double? minimumTemperature = ingredient.minimumTemperature;
    double? maximumTemperature = ingredient.maximumTemperature;

    if (ingredient.type == 'item') {
      if (qualityMin == null && qualityMax != null) {
        // TODO
      }
    }
  }
}

class InGameRecipeProduct implements RecipeProduct {
  @override
  final InGameItem item;
  final RecipeProduct internal;

  InGameRecipeProduct(this.internal, Quality quality)
    : item = InGameItem(
        internal.item,
        quality: quality,
        temperature: internal.temperature,
      );

  @override
  double? get amount => internal.amount;
  @override
  double? get amountMax => internal.amountMax;
  @override
  double? get amountMin => internal.amountMin;
  @override
  double? get extraCountFraction => internal.extraCountFraction;
  @override
  FactorioDatabase get factorioDb => internal.factorioDb;
  @override
  double get ignoredByProductivity => internal.ignoredByProductivity;
  @override
  double? get percentSpoiled => internal.percentSpoiled;
  @override
  double get independentProbability => internal.independentProbability;
  @override
  SharedProbability get sharedProbability => internal.sharedProbability;
  @override
  double? get temperature => internal.temperature;
  @override
  String get type => internal.type;

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
