part of '../production_line.dart';

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

class ModuledMachine implements Updateable {
  CraftingMachine craftingMachine;

  ModuledMachine(this.craftingMachine);

  @override
  // TODO: implement awaitingUpdate
  bool get awaitingUpdate => throw UnimplementedError();

  @override
  void update() {
    // TODO: implement update
  }
}