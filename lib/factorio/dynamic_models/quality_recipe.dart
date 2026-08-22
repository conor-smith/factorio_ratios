part of 'dynamic_models.dart';

class _QualityRecipeImpl extends DelegatingRecipe
    with QualityPrototype
    implements QualityRecipe {
  @override
  final Recipe internal;
  @override
  final Quality quality;

  @override
  final List<QualityRecipeIngredient> ingredients;
  @override
  final List<QualityRecipeProduct> results;
  @override
  final ItemEntity? mainProduct;

  factory _QualityRecipeImpl(Recipe recipe, [Quality? quality]) {
    quality ??= recipe.factorioDb.defaultQuality;

    if (recipe is DelegatingRecipe) {
      recipe = recipe.internal;
    }
    return _QualityRecipeImpl._(recipe, quality);
  }

  _QualityRecipeImpl._(this.internal, this.quality)
    : mainProduct = internal.mainProduct != null
          ? ItemEntity(internal.mainProduct!)
          : null,
      ingredients = List.unmodifiable(
        internal.ingredients.map(
          (ingredient) => _QualityRecipeIngredientImpl(ingredient, quality),
        ),
      ),
      results = List.unmodifiable(
        internal.results.map(
          (product) => _QualityRecipeProductImpl(product, quality),
        ),
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

class _QualityRecipeIngredientImpl extends DelegatingRecipeIngredient
    implements QualityRecipeIngredient {
  @override
  final RecipeIngredient internal;

  @override
  final ItemInputSpec item;

  _QualityRecipeIngredientImpl._(this.internal, this.item);

  factory _QualityRecipeIngredientImpl(
    RecipeIngredient ingredient,
    Quality recipeQuality,
  ) {
    Item item = ingredient.item;

    if (item is SolidItem) {
      Quality? qualityMin = ingredient.qualityMin;
      Quality? qualityMax = ingredient.qualityMax;
      if (qualityMin == null && qualityMax != null) {
        qualityMin = qualityMax.firstQualityInChain;
      } else if (qualityMin != null && qualityMax == null) {
        qualityMax = qualityMin.finalQualityInChain;
      } else if (qualityMin == null && qualityMax == null) {
        qualityMin = recipeQuality;
        qualityMax = recipeQuality;
      }

      return _QualityRecipeIngredientImpl._(
        ingredient,
        SolidItemInputSpec(
          item,
          qualityMin: qualityMin,
          qualityMax: qualityMax,
        ),
      );
    } else {
      item = item as FluidItem;

      double? temperature = ingredient.temperature;
      double? minimumTemperature = ingredient.minimumTemperature;
      double? maximumTemperature = ingredient.maximumTemperature;

      if (temperature == null) {
        minimumTemperature ??= item.defaultTemperature;
        maximumTemperature ??= item.maxTemperature;
      } else {
        minimumTemperature = temperature;
        maximumTemperature = temperature;
      }

      return _QualityRecipeIngredientImpl._(
        ingredient,
        FluidItemInputSpec(
          item,
          minimumTemperature: minimumTemperature,
          maximumTemperature: maximumTemperature,
        ),
      );
    }
  }
}

class _QualityRecipeProductImpl extends DelegatingRecipeProduct
    implements QualityRecipeProduct {
  @override
  final RecipeProduct internal;

  @override
  final ItemOutputSpec item;

  _QualityRecipeProductImpl._(this.internal, this.item);

  factory _QualityRecipeProductImpl(
    RecipeProduct product,
    Quality recipeQuality,
  ) {
    Item item = product.item;

    if (item is SolidItem) {
      Quality? qualityMin = product.qualityMin;
      Quality? qualityMax = product.qualityMax;
      if (qualityMin == null && qualityMax != null) {
        qualityMin = qualityMax.firstQualityInChain;
      } else if (qualityMin != null && qualityMax == null) {
        qualityMax = qualityMin.finalQualityInChain;
      } else if (qualityMin == null && qualityMax == null) {
        qualityMin = recipeQuality;
        qualityMax = recipeQuality;
      }

      return _QualityRecipeProductImpl._(
        product,
        SolidItemOutputSpec(
          item,
          qualityMin: qualityMin,
          qualityMax: qualityMax,
        ),
      );
    } else {
      item = item as FluidItem;

      double temperature = product.temperature ?? item.defaultTemperature;

      return _QualityRecipeProductImpl._(
        product,
        FluidItemInputSpec(
          item,
          minimumTemperature: temperature,
          maximumTemperature: temperature,
        ),
      );
    }
  }
}
