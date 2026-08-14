part of 'dynamic_models.dart';

abstract class ItemSpec implements DelegatingItem, ToJson {
  bool accepts(Item item);

  factory ItemSpec(
    Item item, {
    Quality? qualityMin,
    Quality? qualityMax,
    double? minimumTemperature,
    double? maximumTemperature,
  }) {
    if (item is DelegatingItem) {
      item = item.internal;
    }

    if (item is SolidItem) {
      qualityMin ??= item.factorioDb.defaultQuality;
      qualityMax ??= item.factorioDb.defaultQuality;

      return SolidItemSpec._(item, qualityMin, qualityMax);
    } else {
      item = item as FluidItem;
      minimumTemperature ??= item.defaultTemperature;
      maximumTemperature ??= item.defaultTemperature;

      return FluidItemSpec._(item, minimumTemperature, maximumTemperature);
    }
  }
}

class SolidItemSpec extends DelegatingSolidItem implements ItemSpec {
  @override
  final SolidItem internal;

  final Quality qualityMin;
  final Quality qualityMax;

  @override
  final Icon? icon;

  SolidItemSpec._(this.internal, this.qualityMin, this.qualityMax)
    : icon = internal.icon?.withQuality(qualityMin);

  @override
  bool accepts(Item item) =>
      item is InGameSolidItem &&
      item.quality >= qualityMin &&
      item.quality <= qualityMax;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is SolidItemSpec &&
          internal == other.internal &&
          qualityMin == other.qualityMin &&
          qualityMax == other.qualityMax;

  @override
  int get hashCode =>
      internal.hashCode + qualityMin.hashCode + (qualityMax.hashCode * 10);
}

class FluidItemSpec extends DelegatingFluidItem implements ItemSpec {
  @override
  final FluidItem internal;

  final double minimumTemperature;
  final double maximumTemperature;

  FluidItemSpec._(
    this.internal,
    this.minimumTemperature,
    this.maximumTemperature,
  );

  @override
  bool accepts(Item item) =>
      item is InGameFluidItem &&
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
      other is FluidItemSpec &&
          internal == other.internal &&
          minimumTemperature == other.minimumTemperature &&
          maximumTemperature == other.maximumTemperature;

  @override
  int get hashCode =>
      internal.hashCode +
      minimumTemperature.hashCode +
      (maximumTemperature * 32).hashCode;
}
