part of 'dynamic_models.dart';

class InGameMachine implements CraftingMachine {
  // TODO - Quality effects
  final CraftingMachine internalMachine;

  final int quality;
  @override
  final String name;
  @override
  final InGameItem? item;

  InGameMachine(this.internalMachine, [this.quality = 1])
    : name = internalMachine.name + (quality == 1 ? '' : ': Q$quality'),
      item = internalMachine.item != null
          ? InGameItem(internalMachine.item!, quality: quality)
          : null;

  @override
  double get energyUsage => internalMachine.energyUsage;
  @override
  double get craftingSpeed => internalMachine.craftingSpeed;
  @override
  List<String> get allowedEffects => internalMachine.allowedEffects;
  @override
  bool get needsFuel => internalMachine.needsFuel;
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
  int compareTo(Ordered other) => internalMachine.compareTo(other);
  @override
  double get defaultScale => internalMachine.defaultScale;
  @override
  double get expectedIconSize => internalMachine.expectedIconSize;
  @override
  List<IconData>? get icons => internalMachine.icons;
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
}
