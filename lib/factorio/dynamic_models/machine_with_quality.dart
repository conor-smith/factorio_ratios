part of 'dynamic_models.dart';

class CraftingMachineWithQuality implements CraftingMachine {
  // TODO - Quality effects
  final CraftingMachine internalMachine;

  final int quality;
  @override
  final String name;

  CraftingMachineWithQuality(this.internalMachine, [this.quality = 1])
    : name = internalMachine.name + (quality == 1 ? '' : ': Q$quality');

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
  String toString() => name;
}
