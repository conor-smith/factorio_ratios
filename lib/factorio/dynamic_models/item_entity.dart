part of 'dynamic_models.dart';

abstract class ItemEntity implements DelegatingItem, ItemOutputSpec {
  factory ItemEntity(Item item, {Quality? quality, double? temperature}) {
    if (item is SolidItem) {
      return SolidItemEntity(item, quality: quality);
    } else {
      item = item as FluidItem;

      return FluidItemEntity(item, temperature: temperature);
    }
  }
}

class SolidItemEntity extends DelegatingSolidItem
    with QualityPrototype
    implements ItemEntity, SolidItemOutputSpec {
  @override
  final SolidItem internal;
  @override
  final Quality quality;

  @override
  final SolidItemEntity? spoilResult;
  @override
  final SolidItemEntity? burntResult;

  @override
  final List<SolidItemEntity> producedFromSpoiling;
  @override
  final List<SolidItem> producedFromBurning;

  final double percentSpoiled;

  @override
  final int hashCode;

  factory SolidItemEntity(
    SolidItem item, {
    Quality? quality,
    double percentSpoiled = 0,
  }) {
    if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    quality ??= item.factorioDb.defaultQuality;

    SolidItemEntity? spoilResult = item.spoilResult != null
        ? SolidItemEntity(
            item.spoilResult!,
            quality: quality + item.spoilQualityChange,
          )
        : null;
    SolidItemEntity? burntResult = item.burntResult != null
        ? SolidItemEntity(item.burntResult!)
        : null;

    Iterable<SolidItemEntity> producedFromSpoiling = item.producedFromSpoiling
        .map((spoilableItem) {
          var requiredQuality = quality! - spoilableItem.spoilQualityChange;

          if (requiredQuality == null) {
            return null;
          } else {
            return SolidItemEntity(item, quality: requiredQuality);
          }
        })
        .nonNulls;

    Iterable<SolidItem> producedFromBurning =
        quality == item.factorioDb.defaultQuality
        ? item.producedFromBurning
        : const [];

    return SolidItemEntity._(
      internal: item,
      quality: quality,
      spoilResult: spoilResult,
      burntResult: burntResult,
      percentSpoiled: percentSpoiled,
      producedFromSpoiling: producedFromSpoiling,
      producedFromBurning: producedFromBurning,
    );
  }

  SolidItemEntity._({
    required this.internal,
    required this.quality,
    required this.spoilResult,
    required this.burntResult,
    required this.percentSpoiled,
    required Iterable<SolidItemEntity> producedFromSpoiling,
    required Iterable<SolidItem> producedFromBurning,
  }) : producedFromSpoiling = List.unmodifiable(producedFromSpoiling),
       producedFromBurning = List.unmodifiable(producedFromBurning),
       hashCode =
           internal.hashCode +
           quality.hashCode +
           spoilResult.hashCode +
           (burntResult.hashCode * 2) +
           createHashFromIterable(producedFromSpoiling) +
           createHashFromIterable(producedFromBurning) +
           10;

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is SolidItemEntity && hashCode == other.hashCode);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class FluidItemEntity extends DelegatingFluidItem
    implements ItemEntity, FluidItemOutputSpec {
  @override
  final FluidItem internal;
  @override
  final double temperature;

  @override
  final String name;

  factory FluidItemEntity(FluidItem item, {double? temperature}) {
    if (item is FluidItemEntity && temperature == item.temperature) {
      return item;
    } else if (item is DelegatingFluidItem) {
      item = item.internal;
    }

    temperature ??= item.defaultTemperature;
    return FluidItemEntity._(item, temperature);
  }

  FluidItemEntity._(this.internal, this.temperature)
    : name = '${internal.name}: T$temperature';

  // Ensure that fluids of different temperature are sorted
  @override
  int compareTo(Prototype other) {
    if (other is FluidItemEntity && internal == other.internal) {
      return temperature.compareTo(other.temperature);
    } else {
      return super.compareTo(other);
    }
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is FluidItemEntity && hashCode == other.hashCode);

  @override
  int get hashCode => internal.hashCode + temperature.hashCode + 10;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
