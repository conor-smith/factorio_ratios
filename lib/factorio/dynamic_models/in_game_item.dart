part of 'dynamic_models.dart';

abstract class InGameItem implements Item, ToJson {
  Item get internalItem;

  InGameItem._();

  factory InGameItem(Item item, {int quality = 1, double? temperature}) {
    if (item is InGameSolidItem) {
      return InGameSolidItem(item.internalItem, quality);
    } else if (item is InGameFluidItem) {
      return InGameFluidItem(
        item.internalItem,
        temperature ?? item.defaultTemperature,
      );
    } else if (item is SolidItem) {
      return InGameSolidItem(item, quality);
    } else {
      item = item as FluidItem;
      return InGameFluidItem(item, temperature ?? item.defaultTemperature);
    }
  }

  @override
  FactorioDatabase get factorioDb => internalItem.factorioDb;

  @override
  int compareTo(Prototype other) => internalItem.compareTo(other);

  @override
  List<Recipe> get consumedBy => internalItem.consumedBy;

  @override
  double? get fuelValue => internalItem.fuelValue;

  @override
  bool get hidden => internalItem.hidden;

  @override
  String get localisedName => internalItem.localisedName;

  @override
  String get order => internalItem.order;

  @override
  List<Recipe> get producedBy => internalItem.producedBy;

  @override
  ItemSubgroup? get subgroup => internalItem.subgroup;

  @override
  String get type => internalItem.type;

  @override
  String toString() => name;
}

// TODO - Add spoilage
class InGameSolidItem extends InGameItem implements SolidItem {
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

  InGameSolidItem(this.internalItem, [this.quality = 1])
    : name = internalItem.name + (quality == 1 ? '' : ': Q$quality'),
      icon = internalItem.icon?.withQuality(quality),
      spoilResult = internalItem.spoilResult != null
          ? InGameItem(internalItem.spoilResult!)
          : null,
      burntResult = internalItem.burntResult != null
          ? InGameItem(internalItem.burntResult!)
          : null,
      super._();

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
  String? get fuelCategory => internalItem.fuelCategory;
  @override
  double? get fuelEmissionsMultiplier => internalItem.fuelEmissionsMultiplier;
  @override
  List<Item> get producedFromBurning => internalItem.producedFromBurning;
  @override
  List<Item> get producedFromSpoiling => internalItem.producedFromSpoiling;
  @override
  int? get spoilTicks => internalItem.spoilTicks;
  @override
  int get stackSize => internalItem.stackSize;

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

class InGameFluidItem extends InGameItem implements FluidItem {
  @override
  final FluidItem internalItem;
  final double temperature;

  @override
  final String name;

  InGameFluidItem(this.internalItem, this.temperature)
    : name = '${internalItem.name}: T$temperature',
      super._();

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
  Icon? get icon => internalItem.icon;

  @override
  double get defaultTemperature => internalItem.defaultTemperature;
  @override
  double get emissionsMultiplier => internalItem.emissionsMultiplier;
  @override
  double get heatCapacity => internalItem.heatCapacity;
  @override
  double get maxTemperature => internalItem.maxTemperature;

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
