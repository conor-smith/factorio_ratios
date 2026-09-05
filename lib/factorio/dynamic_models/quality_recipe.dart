part of 'dynamic_models.dart';

class _QualityRecipeImpl extends DelegatingRecipe
    with QualityPrototype
    implements QualityRecipe {
  @override
  final Recipe internal;
  @override
  final Quality quality;

  @override
  final ItemEntity? mainProduct;

  @override
  final List<RecipeIngredient> ingredients;
  @override
  final List<RecipeProduct> results;

  factory _QualityRecipeImpl(Recipe recipe, [Quality? quality]) {
    if (recipe is DelegatingRecipe) {
      recipe = recipe.internal;
    }

    if (quality == null || !recipe.canSetQuality) {
      quality = recipe.factorioDb.defaultQuality;
    }

    return _QualityRecipeImpl._(recipe, quality);
  }

  _QualityRecipeImpl._(this.internal, this.quality)
    : mainProduct = internal.mainProduct != null
          ? ItemEntity(internal.mainProduct!)
          : null,
      ingredients = List.unmodifiable(
        internal.ingredients.map(
          (ingredient) => ingredient.withQuality(quality),
        ),
      ),
      results = List.unmodifiable(
        internal.results.map((result) => result.withQuality(quality)),
      );

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is QualityRecipe &&
          internal == other.internal &&
          quality == other.quality;

  @override
  int get hashCode => internal.hashCode + quality.hashCode;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
