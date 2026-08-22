part of 'dynamic_models.dart';

class _SolidItemEntityImpl extends DelegatingSolidItem
    with QualityPrototype
    implements SolidItemEntity {
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

  @override
  final double percentSpoiled;

  @override
  final int hashCode;

  factory _SolidItemEntityImpl(
    SolidItem item, {
    Quality? quality,
    double percentSpoiled = 0,
  }) {
    if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    quality ??= item.factorioDb.defaultQuality;

    _SolidItemEntityImpl? spoilResult = item.spoilResult != null
        ? _SolidItemEntityImpl(
            item.spoilResult!,
            quality: quality + item.spoilQualityChange,
          )
        : null;
    _SolidItemEntityImpl? burntResult = item.burntResult != null
        ? _SolidItemEntityImpl(item.burntResult!)
        : null;

    Iterable<_SolidItemEntityImpl> producedFromSpoiling = item
        .producedFromSpoiling
        .map((spoilableItem) {
          var requiredQuality = quality! - spoilableItem.spoilQualityChange;

          if (requiredQuality == null) {
            return null;
          } else {
            return _SolidItemEntityImpl(item, quality: requiredQuality);
          }
        })
        .nonNulls;

    Iterable<SolidItem> producedFromBurning =
        quality == item.factorioDb.defaultQuality
        ? item.producedFromBurning
        : const [];

    return _SolidItemEntityImpl._(
      internal: item,
      quality: quality,
      spoilResult: spoilResult,
      burntResult: burntResult,
      percentSpoiled: percentSpoiled,
      producedFromSpoiling: producedFromSpoiling,
      producedFromBurning: producedFromBurning,
    );
  }

  _SolidItemEntityImpl._({
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
      (other is _SolidItemEntityImpl && hashCode == other.hashCode);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class _FluidItemEntityImpl extends DelegatingFluidItem
    implements FluidItemEntity {
  @override
  final FluidItem internal;
  @override
  final double temperature;

  @override
  final String name;

  factory _FluidItemEntityImpl(FluidItem item, {double? temperature}) {
    if (item is DelegatingFluidItem) {
      item = item.internal;
    }

    temperature ??= item.defaultTemperature;
    return _FluidItemEntityImpl._(item, temperature);
  }

  _FluidItemEntityImpl._(this.internal, this.temperature)
    : name = '${internal.name}: T$temperature';

  // Ensure that fluids of different temperature are sorted
  @override
  int compareTo(Prototype other) {
    if (other is _FluidItemEntityImpl && internal == other.internal) {
      return temperature.compareTo(other.temperature);
    } else {
      return super.compareTo(other);
    }
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is _FluidItemEntityImpl &&
          internal == other.internal &&
          temperature == other.temperature);

  @override
  int get hashCode => internal.hashCode + temperature.hashCode + 10;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
