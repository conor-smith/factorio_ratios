part of 'dynamic_models.dart';

// Due to the complexity and overlap of classes, all leaf classes
// in this package are defined via composition rather than inheritance.
// The "base classes" are either the delegating classes, or the underlying
// model classes themselves.
// This approach does result in duplication
// but makes the code far easier to maintain

mixin QualityPrototype on PrototypeWithIcon {
  Quality get quality;

  @override
  String get name {
    if (quality == factorioDb.defaultQuality) {
      return super.name;
    } else {
      return '${quality.name} ${super.name}';
    }
  }

  @override
  Icon? get icon => super.icon?.withQuality(quality);
}

abstract class ItemInputSpec implements DelegatingItem, ToJson {
  bool accepts(Item item);

  factory ItemInputSpec(
    Item item, {
    Quality? qualityMin,
    Quality? qualityMax,
    double? minimumTemperature,
    double? maximumTemperature,
  }) {
    if (item is SolidItem) {
      return SolidItemInputSpec(
        item,
        qualityMin: qualityMin,
        qualityMax: qualityMax,
      );
    } else {
      item = item as FluidItem;

      return FluidItemInputSpec(
        item,
        minimumTemperature: minimumTemperature,
        maximumTemperature: maximumTemperature,
      );
    }
  }
}

abstract class SolidItemInputSpec
    implements ItemInputSpec, DelegatingSolidItem {
  Quality? get qualityMin;
  Quality? get qualityMax;

  factory SolidItemInputSpec.allQualities(SolidItem item) =>
      _SolidItemInputSpecImpl.allQualities(item);

  factory SolidItemInputSpec(
    SolidItem internal, {
    Quality? qualityMin,
    Quality? qualityMax,
  }) => _SolidItemInputSpecImpl(
    internal,
    qualityMin: qualityMin,
    qualityMax: qualityMax,
  );
}

abstract class FluidItemInputSpec extends DelegatingFluidItem
    implements ItemInputSpec {
  double get minimumTemperature;
  double get maximumTemperature;

  factory FluidItemInputSpec(
    FluidItem internal, {
    double? minimumTemperature,
    double? maximumTemperature,
  }) => _FluidItemInputSpecImpl(
    internal,
    minimumTemperature: minimumTemperature,
    maximumTemperature: maximumTemperature,
  );

  @override
  bool accepts(Item item) =>
      item is FluidItemEntity &&
      item.internal == internal &&
      item.temperature >= minimumTemperature &&
      item.temperature <= maximumTemperature;
}

abstract class ItemOutputSpec implements DelegatingItem, ToJson {}

abstract class SolidItemOutputSpec
    implements ItemOutputSpec, QualityPrototype, DelegatingSolidItem {
  @override
  Quality get quality;

  factory SolidItemOutputSpec(SolidItem item, {Quality? quality}) =>
      _SolidItemOutputSpecImpl(item, quality: quality);
}

abstract class FluidItemOutputSpec
    implements DelegatingFluidItem, ItemOutputSpec {
  @override
  FluidItem get internal;
  double get temperature;

  factory FluidItemOutputSpec(FluidItem item, {double? temperature}) =>
      _FluidItemOutputSpecImpl(item, temperature: temperature);
}

abstract class ItemEntity implements DelegatingItem, ItemOutputSpec {
  factory ItemEntity(Item item, {Quality? quality, double? temperature}) {
    if (item is SolidItem) {
      return SolidItemEntity(item, quality: quality);
    } else {
      return FluidItemEntity(item as FluidItem, temperature: temperature);
    }
  }
}

abstract class SolidItemEntity
    implements
        DelegatingSolidItem,
        ItemEntity,
        SolidItemOutputSpec,
        QualityPrototype {
  @override
  SolidItemEntity? get spoilResult;
  @override
  SolidItemEntity? get burntResult;

  @override
  List<SolidItemEntity> get producedFromSpoiling;
  @override
  List<SolidItem> get producedFromBurning;

  double get percentSpoiled;

  factory SolidItemEntity(
    SolidItem item, {
    Quality? quality,
    double percentSpoiled = 0,
  }) => _SolidItemEntityImpl(
    item,
    quality: quality,
    percentSpoiled: percentSpoiled,
  );
}

abstract class FluidItemEntity
    implements DelegatingFluidItem, ItemEntity, FluidItemOutputSpec {
  factory FluidItemEntity(FluidItem item, {double? temperature}) =>
      _FluidItemEntityImpl(item, temperature: temperature);
}

abstract class MachineEntity
    implements DelegatingCraftingMachine, QualityPrototype, ToJson {
  // TODO - Quality effects

  @override
  ItemEntity? get item;

  factory MachineEntity(CraftingMachine machine, [Quality? quality]) =>
      _MachineEntityImpl(machine, quality);
}

abstract class QualityRecipe
    implements DelegatingRecipe, QualityPrototype, ToJson {
  @override
  List<QualityRecipeIngredient> get ingredients;
  @override
  List<QualityRecipeProduct> get results;
  @override
  ItemOutputSpec? get mainProduct;

  factory QualityRecipe(Recipe recipe, [Quality? quality]) =>
      throw UnimplementedError();
}

abstract class QualityRecipeIngredient implements DelegatingRecipeIngredient {
  @override
  ItemInputSpec get item;

  factory QualityRecipeIngredient(
    RecipeIngredient ingredient,
    Quality recipeQuality,
  ) => throw UnimplementedError();
}

abstract class QualityRecipeProduct extends DelegatingRecipeProduct {
  @override
  ItemOutputSpec get item;

  factory QualityRecipeProduct(RecipeProduct product, Quality recipeQuality) =>
      throw UnimplementedError();
}
