part of 'dynamic_models.dart';

class InGameMachine implements CraftingMachine, ToJson {
  // TODO - Quality effects
  final CraftingMachine internalMachine;

  final int quality;
  @override
  final String name;
  @override
  final InGameItem? item;
  @override
  final Icon? icon;

  factory InGameMachine(CraftingMachine internalMachine, [int quality = 1]) {
    if (internalMachine is InGameMachine) {
      return internalMachine;
    } else {
      return InGameMachine._(internalMachine, quality);
    }
  }

  InGameMachine._(this.internalMachine, this.quality)
    : name = internalMachine.name + (quality == 1 ? '' : ': Q$quality'),
      item = internalMachine.item != null
          ? InGameItem(internalMachine.item!, quality: quality)
          : null,
      icon = internalMachine.icon != null
          ? Icon.withQuality(internalMachine.icon!, quality)
          : null;

  // Ensure that machines of different quality are separated
  @override
  int compareTo(Prototype other) {
    if (other is InGameMachine) {
      if (quality > other.quality) {
        return -1;
      } else if (quality < other.quality) {
        return 1;
      }
    }
    return internalMachine.compareTo(other);
  }

  @override
  String get type => internalMachine.type;
  @override
  double get energyUsage => internalMachine.energyUsage;
  @override
  double get craftingSpeed => internalMachine.craftingSpeed;
  @override
  List<String> get allowedEffects => internalMachine.allowedEffects;
  @override
  bool get needsSolidFuel => internalMachine.needsSolidFuel;
  @override
  List<String> get craftingCategories => internalMachine.craftingCategories;
  @override
  EffectReceiver get effectReceiver => internalMachine.effectReceiver;
  @override
  CraftingMachineEnergySource get energySource => internalMachine.energySource;
  @override
  FactorioDatabase get factorioDb => internalMachine.factorioDb;
  @override
  String get localisedName => internalMachine.localisedName;
  @override
  int get moduleSlots => internalMachine.moduleSlots;
  @override
  List<Recipe> get recipes => internalMachine.recipes;
  @override
  double get defaultScale => internalMachine.defaultScale;
  @override
  double get expectedIconSize => internalMachine.expectedIconSize;
  @override
  String get order => internalMachine.order;
  @override
  ItemSubgroup? get subgroup => internalMachine.subgroup;
  @override
  List<Item> get fuelItems => internalMachine.fuelItems;

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is InGameMachine &&
          internalMachine == other.internalMachine &&
          quality == other.quality;

  @override
  int get hashCode => internalMachine.hashCode + quality;

  @override
  String toString() => name;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
