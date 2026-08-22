part of 'dynamic_models.dart';

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

class SolidItemInputSpec extends DelegatingSolidItem implements ItemInputSpec {
  @override
  final SolidItem internal;

  final Quality? qualityMin;
  final Quality? qualityMax;

  @override
  final Icon? icon;

  SolidItemInputSpec._(this.internal, this.qualityMin, this.qualityMax)
    : icon = internal.icon?.withQuality(qualityMin);

  factory SolidItemInputSpec.allQualities(SolidItem item) {
    if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    return SolidItemInputSpec._(item, null, null);
  }

  factory SolidItemInputSpec(
    SolidItem internal, {
    Quality? qualityMin,
    Quality? qualityMax,
  }) {
    if (internal is DelegatingSolidItem) {
      internal = internal.internal;
    }

    qualityMin ??= internal.factorioDb.defaultQuality;
    qualityMax ??= internal.factorioDb.defaultQuality;

    return SolidItemInputSpec._(internal, qualityMin, qualityMax);
  }

  @override
  bool accepts(Item item) =>
      item is SolidItemEntity &&
      item.internal == internal &&
      (qualityMin == null ||
          (qualityMin!.chainCompare(item.quality).lessThanOrEqual &&
              qualityMax!.chainCompare(item.quality).greaterThanOrEqual));

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is SolidItemInputSpec &&
          internal == other.internal &&
          qualityMin == other.qualityMin &&
          qualityMax == other.qualityMax;

  @override
  int get hashCode =>
      internal.hashCode + qualityMin.hashCode + (qualityMax.hashCode * 10);
}

class FluidItemInputSpec extends DelegatingFluidItem implements ItemInputSpec {
  @override
  final FluidItem internal;

  final double minimumTemperature;
  final double maximumTemperature;

  FluidItemInputSpec._(
    this.internal,
    this.minimumTemperature,
    this.maximumTemperature,
  );

  factory FluidItemInputSpec(
    FluidItem internal, {
    double? minimumTemperature,
    double? maximumTemperature,
  }) {
    if (internal is DelegatingFluidItem) {
      internal = internal.internal;
    }

    minimumTemperature ??= internal.defaultTemperature;
    maximumTemperature ??= internal.defaultTemperature;

    return FluidItemInputSpec._(
      internal,
      minimumTemperature,
      maximumTemperature,
    );
  }

  @override
  bool accepts(Item item) =>
      item is FluidItemEntity &&
      item.internal == internal &&
      item.temperature >= minimumTemperature &&
      item.temperature <= maximumTemperature;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is FluidItemInputSpec &&
          internal == other.internal &&
          minimumTemperature == other.minimumTemperature &&
          maximumTemperature == other.maximumTemperature;

  @override
  int get hashCode =>
      internal.hashCode +
      minimumTemperature.hashCode +
      (maximumTemperature * 32).hashCode;
}

abstract class ItemOutputSpec implements DelegatingItem, ToJson {}

class SolidItemOutputSpec extends DelegatingSolidItem
    implements ItemOutputSpec, QualityPrototype {
  @override
  SolidItem internal;

  @override
  final Quality quality;

  SolidItemOutputSpec._(this.internal, this.quality);

  factory SolidItemOutputSpec(SolidItem item, {Quality? quality}) {
    if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    quality ??= item.factorioDb.defaultQuality;

    return SolidItemOutputSpec._(item, quality);
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
