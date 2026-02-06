part of '../production_line.dart';

class SingleRecipeLine extends ProductionLine with ModuledMachineMixin {
  final QualityRecipe qRecipe;
  CraftingMachine _craftingMachine;
  double _machineAmount = 1;
  bool _machineChange = false;

  final Map<ItemData, double> _ioPerSecond = {};
  @override
  late final Map<ItemData, double> ioPerSecond = UnmodifiableMapView(
    _ioPerSecond,
  );

  SingleRecipeLine(this.qRecipe, this._craftingMachine) {
    _verifyMachineCompatibility(_craftingMachine);

    for (var ingredient in qRecipe.recipe.ingredients) {
      _ioPerSecond[ItemData(ingredient.item)] = -ingredient.amount;
    }

    for (var result in qRecipe.recipe.results) {
      _ioPerSecond.update(
        (ItemData(result.item)),
        (amount) => amount += result.amount,
        ifAbsent: () => result.amount,
      );
    }
  }

  void _verifyMachineCompatibility(CraftingMachine newMachine) {
    if (!newMachine.recipes.contains(qRecipe.recipe)) {
      throw FactorioException(
        'Machine "${newMachine.name}" cannot craft recipe "${qRecipe.recipe.name}"',
      );
    }
  }

  @override
  void update(Map<ItemData, double> requirements) {
    // TODO: implement calculate
  }

  @override
  String get name => 'Recipe: ${qRecipe.recipe.name}';
}
