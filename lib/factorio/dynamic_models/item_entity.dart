part of 'dynamic_models.dart';

abstract class ItemEntity implements DelegatingItem, ToJson {
  factory ItemEntity(Item item, {Quality? quality, double? temperature}) {
    if (item is SolidItem) {
      return SolidItemEntity(item, quality: quality);
    } else {
      item = item as FluidItem;

      return FluidItemEntity(item, temperature: temperature);
    }
  }
}

// TODO - Add spoilage
class SolidItemEntity extends DelegatingSolidItem
    implements ItemEntity, QualityPrototype {
  @override
  final SolidItem internal;
  @override
  final Quality quality;

  @override
  final String name;
  @override
  final Icon? icon;

  @override
  final ItemEntity? spoilResult;
  @override
  final ItemEntity? burntResult;

  factory SolidItemEntity(SolidItem item, {Quality? quality}) {
    quality ??= item.factorioDb.defaultQuality;

    if (item is SolidItemEntity && item.quality == quality) {
      return item;
    } else if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    return SolidItemEntity._(item, quality);
  }

  SolidItemEntity._(this.internal, this.quality)
    : name = quality.name != Quality.defaultName
          ? '$quality ${internal.name}'
          : internal.name,
      icon = internal.icon?.withQuality(quality),
      spoilResult = internal.spoilResult != null
          ? ItemEntity(internal.spoilResult!)
          : null,
      burntResult = internal.burntResult != null
          ? ItemEntity(internal.burntResult!)
          : null;

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is SolidItemEntity &&
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

class FluidItemEntity extends DelegatingFluidItem implements ItemEntity {
  @override
  final FluidItem internal;
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
      other is FluidItemEntity &&
          internal == other.internal &&
          temperature == other.temperature;

  @override
  int get hashCode => internal.hashCode + temperature.hashCode;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
