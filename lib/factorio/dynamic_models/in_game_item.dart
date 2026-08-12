part of 'dynamic_models.dart';

abstract class InGameItem implements ItemSpec {
  factory InGameItem(Item item, {int quality = 1, double? temperature}) {
    // TODO - if Item is already InGameItem, return item if matches arguements

    if (item is DelegatingItem) {
      item = item.internalItem;
    }

    if (item is SolidItem) {
      return InGameSolidItem._(item, quality);
    } else {
      item = item as FluidItem;
      temperature ??= item.defaultTemperature;

      return InGameFluidItem._(item, temperature);
    }
  }
}

// TODO - Add spoilage
class InGameSolidItem extends DelegatingSolidItem
    implements InGameItem, SolidItemSpec {
  @override
  final SolidItem internalItem;
  final int quality;

  @override
  final String name;
  @override
  final Icon? icon;

  @override
  final InGameItem? spoilResult;
  @override
  final InGameItem? burntResult;

  @override
  int get qualityMin => quality;
  @override
  int get qualityMax => quality;

  InGameSolidItem._(this.internalItem, this.quality)
    : name = internalItem.name + (quality == 1 ? '' : ': Q$quality'),
      icon = internalItem.icon?.withQuality(quality),
      spoilResult = internalItem.spoilResult != null
          ? InGameItem(internalItem.spoilResult!)
          : null,
      burntResult = internalItem.burntResult != null
          ? InGameItem(internalItem.burntResult!)
          : null;

  @override
  bool accepts(Item item) =>
      item is InGameSolidItem &&
      item.internalItem == internalItem &&
      item.quality == quality;

  // Ensure that items of different quality are separated
  @override
  int compareTo(Prototype other) {
    if (other is InGameSolidItem) {
      if (quality > other.quality) {
        return -1;
      } else if (quality < other.quality) {
        return 1;
      }
    }
    return super.compareTo(other);
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is InGameSolidItem &&
          internalItem == other.internalItem &&
          quality == other.quality;

  @override
  int get hashCode => internalItem.hashCode + quality;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class InGameFluidItem extends DelegatingFluidItem
    implements InGameItem, FluidItemSpec {
  @override
  final FluidItem internalItem;
  final double temperature;

  @override
  final String name;

  @override
  double get minimumTemperature => temperature;
  @override
  double get maximumTemperature => temperature;

  InGameFluidItem._(this.internalItem, this.temperature)
    : name = '${internalItem.name}: T$temperature';

  @override
  bool accepts(Item item) => this == item;

  // Ensure that fluids of different temperature are sorted
  @override
  int compareTo(Prototype other) {
    if (other is InGameFluidItem && internalItem == other.internalItem) {
      return temperature.compareTo(other.temperature);
    } else {
      return super.compareTo(other);
    }
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is InGameFluidItem &&
          internalItem == other.internalItem &&
          temperature == other.temperature;

  @override
  int get hashCode => internalItem.hashCode + temperature.hashCode;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

abstract class ItemSpec implements DelegatingItem, ToJson {
  bool accepts(Item item);

  factory ItemSpec(
    Item item, {
    int? qualityMin,
    int? qualityMax,
    double? minimumTemperature,
    double? maximumTemperature,
  }) {
    if (item is DelegatingItem) {
      item = item.internalItem;
    }

    if (item is SolidItem) {
      qualityMin ??= 1;
      qualityMax ??= 1;

      return qualityMin == qualityMax
          ? InGameSolidItem._(item, qualityMin)
          : SolidItemSpec._(item, qualityMin, qualityMax);
    } else {
      item = item as FluidItem;
      minimumTemperature ??= item.defaultTemperature;
      maximumTemperature ??= item.defaultTemperature;

      return minimumTemperature == maximumTemperature
          ? InGameFluidItem._(item, minimumTemperature)
          : FluidItemSpec._(item, minimumTemperature, maximumTemperature);
    }
  }
}

class SolidItemSpec extends DelegatingSolidItem implements ItemSpec {
  @override
  final SolidItem internalItem;

  final int qualityMin;
  final int qualityMax;

  @override
  final Icon? icon;

  SolidItemSpec._(this.internalItem, this.qualityMin, this.qualityMax)
    : icon = internalItem.icon?.withQuality(qualityMax);

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
          internalItem == other.internalItem &&
          qualityMin == other.qualityMin &&
          qualityMax == other.qualityMax;

  @override
  int get hashCode => internalItem.hashCode + qualityMin + (qualityMax * 10);
}

class FluidItemSpec extends DelegatingFluidItem implements ItemSpec {
  @override
  final FluidItem internalItem;

  final double minimumTemperature;
  final double maximumTemperature;

  FluidItemSpec._(
    this.internalItem,
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
          internalItem == other.internalItem &&
          minimumTemperature == other.minimumTemperature &&
          maximumTemperature == other.maximumTemperature;

  @override
  int get hashCode =>
      internalItem.hashCode +
      minimumTemperature.hashCode +
      (maximumTemperature * 32).hashCode;
}

abstract class DelegatingItem with Prototype implements Item {
  Item get internalItem;

  @override
  FactorioDatabase get factorioDb => internalItem.factorioDb;

  @override
  String get name => internalItem.name;
  @override
  String get order => internalItem.order;
  @override
  ItemSubgroup? get subgroup => internalItem.subgroup;

  @override
  Icon? get icon => internalItem.icon;

  @override
  String get type => internalItem.type;
  @override
  String get localisedName => internalItem.localisedName;
  @override
  double? get fuelValue => internalItem.fuelValue;

  @override
  bool get hidden => internalItem.hidden;

  @override
  List<Recipe> get consumedBy => internalItem.consumedBy;
  @override
  List<Recipe> get producedBy => internalItem.producedBy;

  @override
  String toString() => internalItem.toString();
}

abstract class DelegatingSolidItem extends DelegatingItem implements SolidItem {
  @override
  SolidItem get internalItem;

  @override
  int get stackSize => internalItem.stackSize;
  @override
  int? get spoilTicks => internalItem.spoilTicks;

  @override
  String? get fuelCategory => internalItem.fuelCategory;
  @override
  double? get fuelEmissionsMultiplier => internalItem.fuelEmissionsMultiplier;

  @override
  Item? get spoilResult => internalItem.spoilResult;
  @override
  List<Item> get producedFromSpoiling => internalItem.producedFromSpoiling;

  @override
  Item? get burntResult => internalItem.burntResult;
  @override
  List<Item> get producedFromBurning => internalItem.producedFromBurning;
}

abstract class DelegatingFluidItem extends DelegatingItem implements FluidItem {
  @override
  FluidItem get internalItem;

  @override
  double get defaultTemperature => internalItem.defaultTemperature;
  @override
  double get heatCapacity => internalItem.heatCapacity;
  @override
  double get maxTemperature => internalItem.maxTemperature;
  @override
  double get emissionsMultiplier => internalItem.emissionsMultiplier;
}
