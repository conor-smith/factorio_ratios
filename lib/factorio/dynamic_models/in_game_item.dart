part of 'dynamic_models.dart';

abstract class InGameItem implements DelegatingItem, ToJson {
  factory InGameItem(Item item, {Quality? quality, double? temperature}) {
    if (item is SolidItem) {
      return InGameSolidItem(item, quality: quality);
    } else {
      item = item as FluidItem;

      return InGameFluidItem(item, temperature: temperature);
    }
  }
}

// TODO - Add spoilage
class InGameSolidItem extends DelegatingSolidItem
    implements InGameItem, QualityPrototype {
  @override
  final SolidItem internal;
  @override
  final Quality quality;

  @override
  final String name;
  @override
  final Icon? icon;

  @override
  final InGameItem? spoilResult;
  @override
  final InGameItem? burntResult;

  factory InGameSolidItem(SolidItem item, {Quality? quality}) {
    quality ??= item.factorioDb.defaultQuality;

    if (item is InGameSolidItem && item.quality == quality) {
      return item;
    } else if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    return InGameSolidItem._(item, quality);
  }

  InGameSolidItem._(this.internal, this.quality)
    : name = quality.name != Quality.defaultName
          ? '$quality ${internal.name}'
          : internal.name,
      icon = internal.icon?.withQuality(quality),
      spoilResult = internal.spoilResult != null
          ? InGameItem(internal.spoilResult!)
          : null,
      burntResult = internal.burntResult != null
          ? InGameItem(internal.burntResult!)
          : null;

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is InGameSolidItem &&
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

class InGameFluidItem extends DelegatingFluidItem implements InGameItem {
  @override
  final FluidItem internal;
  final double temperature;

  @override
  final String name;

  factory InGameFluidItem(FluidItem item, {double? temperature}) {
    if (item is InGameFluidItem && temperature == item.temperature) {
      return item;
    } else if (item is DelegatingFluidItem) {
      item = item.internal;
    }

    temperature ??= item.defaultTemperature;
    return InGameFluidItem._(item, temperature);
  }

  InGameFluidItem._(this.internal, this.temperature)
    : name = '${internal.name}: T$temperature';

  // Ensure that fluids of different temperature are sorted
  @override
  int compareTo(Prototype other) {
    if (other is InGameFluidItem && internal == other.internal) {
      return temperature.compareTo(other.temperature);
    } else {
      return super.compareTo(other);
    }
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is InGameFluidItem &&
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
