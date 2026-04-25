part of 'dynamic_models.dart';

abstract class InGameItem implements Item {
  Item get internalItem;

  InGameItem._();

  factory InGameItem(Item item, {int quality = 1, double? temperature}) {
    if (item is SolidItem) {
      return SolidItemWithQuality(item, quality);
    } else {
      return FluidItemWithTemp(item as FluidItem, temperature);
    }
  }

  @override
  FactorioDatabase get factorioDb => internalItem.factorioDb;

  @override
  int compareTo(Ordered other) => internalItem.compareTo(other);

  @override
  List<Recipe> get consumedBy => internalItem.consumedBy;

  @override
  double get defaultScale => internalItem.defaultScale;

  @override
  double get expectedIconSize => internalItem.expectedIconSize;

  @override
  double? get fuelValue => internalItem.fuelValue;

  @override
  bool get hidden => internalItem.hidden;

  @override
  List<IconData>? get icons => internalItem.icons;

  @override
  String get localisedName => internalItem.localisedName;

  @override
  String get name => internalItem.name;

  @override
  String get order => internalItem.order;

  @override
  List<Recipe> get producedBy => internalItem.producedBy;

  @override
  ItemSubgroup? get subgroup => internalItem.subgroup;

  @override
  String get type => internalItem.type;
}

class SolidItemWithQuality extends InGameItem implements SolidItem {
  @override
  final SolidItem internalItem;
  final int quality;
  @override
  final List<IconData>? icons;

  SolidItemWithQuality(this.internalItem, [this.quality = 1])
    : icons = _verifyQualityAndUpdateIcon(internalItem.icons, quality),
      super._();

  @override
  Item? get burntResult => internalItem.burntResult;
  @override
  Item? get spoilResult => internalItem.spoilResult;
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
      other is SolidItemWithQuality &&
      internalItem == other.internalItem &&
      quality == other.quality;

  @override
  int get hashCode => internalItem.hashCode + quality;

  @override
  String toString() => 'item: $internalItem, quality: $quality';
}

class FluidItemWithTemp extends InGameItem implements FluidItem {
  @override
  final FluidItem internalItem;
  final double temperature;

  FluidItemWithTemp(this.internalItem, [double? temperature])
    : temperature = temperature ?? internalItem.defaultTemperature,
      super._();

  @override
  double get defaultTemperature => internalItem.defaultTemperature;
  @override
  double get emissionsMultipler => internalItem.emissionsMultipler;
  @override
  double get heatCapacity => internalItem.heatCapacity;
  @override
  double get maxTemperature => internalItem.maxTemperature;

  @override
  bool operator ==(Object other) =>
      other is FluidItemWithTemp &&
      internalItem == other.internalItem &&
      temperature == other.temperature;

  @override
  int get hashCode => internalItem.hashCode + temperature.ceil();

  @override
  String toString() => 'fluid: $internalItem, temperature: $temperature';
}
