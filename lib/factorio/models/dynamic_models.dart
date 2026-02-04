part of '../models.dart';

class ItemData {
  final Item item;
  final int quality;
  final double? temperature;

  ItemData._(this.item, this.quality, [this.temperature]);
}

class QualityRecipe {
  final Recipe recipe;
  final int quality;

  QualityRecipe(this.recipe, [this.quality = 1]);
}

class ModuledMachine {
  CraftingMachine _craftingMachine;

  ModuledMachine(this._craftingMachine);

  ModuledMachine.from(ModuledMachine moduledMachine)
    : _craftingMachine = moduledMachine.craftingMachine;

  @override
  CraftingMachine get craftingMachine => _craftingMachine;
  @override
  set craftingMachine(CraftingMachine newMachine) {
    _craftingMachine = newMachine;
  }
}
