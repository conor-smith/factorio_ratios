part of 'dynamic_models.dart';

class QualityRecipe extends DelegatingRecipe
    implements QualityPrototype, ToJson {
  @override
  final Recipe internal;
  @override
  final Quality quality;

  @override
  final String name;
  @override
  final List<QualityRecipeIngredient> ingredients;
  @override
  final List<QualityRecipeProduct> results;
  @override
  final Icon? icon;
  @override
  final ItemEntity? mainProduct;

  factory QualityRecipe(Recipe recipe, [Quality? quality]) {
    quality ??= recipe.factorioDb.defaultQuality;

    if (recipe is QualityRecipe && quality == recipe.quality) {
      return recipe;
    } else if (recipe is DelegatingRecipe) {
      recipe = recipe.internal;
    }
    return QualityRecipe._(recipe, quality);
  }

  QualityRecipe._(this.internal, this.quality)
    : name = quality.name != Quality.defaultName
          ? '$quality ${internal.name}'
          : internal.name,
      icon = internal.icon?.withQuality(quality),
      mainProduct = internal.mainProduct != null
          ? ItemEntity(internal.mainProduct!)
          : null,
      ingredients = List.unmodifiable(
        internal.ingredients.map(
          (ingredient) => QualityRecipeIngredient(ingredient, quality),
        ),
      ),
      results = List.unmodifiable(
        internal.results.map(
          (product) => QualityRecipeProduct(product, quality),
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

class QualityRecipeIngredient extends DelegatingRecipeIngredient {
  @override
  final RecipeIngredient internal;

  @override
  final ItemInputSpec item;

  QualityRecipeIngredient._(this.internal, this.item);

  factory QualityRecipeIngredient(
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

      return QualityRecipeIngredient._(
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

      return QualityRecipeIngredient._(
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

class QualityRecipeProduct extends DelegatingRecipeProduct {
  @override
  final RecipeProduct internal;

  @override
  final ItemInputSpec item;

  QualityRecipeProduct._(this.internal, this.item);

  factory QualityRecipeProduct(RecipeProduct product, Quality recipeQuality) {
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

      return QualityRecipeProduct._(
        product,
        SolidItemInputSpec(
          item,
          qualityMin: qualityMin,
          qualityMax: qualityMax,
        ),
      );
    } else {
      item = item as FluidItem;

      double temperature = product.temperature ?? item.defaultTemperature;

      return QualityRecipeProduct._(
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
