part of 'dynamic_models.dart';

class CraftingMachineWithQuality implements CraftingMachine {
  // TODO - Quality effects
  final CraftingMachine internalMachine;
  final int quality;

  const CraftingMachineWithQuality(this.internalMachine, this.quality);

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
  String get name => internalMachine.name;
  @override
  List<Recipe> get recipes => internalMachine.recipes;
}
