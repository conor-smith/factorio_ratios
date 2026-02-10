part of '../production_line.dart';

class SingleRecipeLine extends ProductionLine {
  final QualityRecipe qRecipe;
  ModuledMachine _moduledMachine;
  double _machineAmount = 1;
  bool _machineChange = false;

  final Map<ItemData, double> _ingredientsPerSecond;
  final Map<ItemData, double> _productsPerSecond;

  @override
  late final Map<ItemData, double> ingredientsPerSecond = UnmodifiableMapView(
    _ingredientsPerSecond,
  );
  @override
  late final Map<ItemData, double> productsPerSecond = UnmodifiableMapView(
    _productsPerSecond,
  );

  SingleRecipeLine(this.qRecipe, this._moduledMachine)
    : _ingredientsPerSecond = Map.fromEntries(
        qRecipe.recipe.ingredients.map(
          (rItem) => MapEntry(ItemData(rItem.item), rItem.amount),
        ),
      ),
      _productsPerSecond = Map.fromEntries(
        qRecipe.recipe.results.map(
          (rItem) => MapEntry(ItemData(rItem.item), rItem.amount),
        ),
      ) {
    _verifyMachineCompatibility(_moduledMachine);

    for(var product in _productsPerSecond.keys) {
      if(_ingredientsPerSecond.containsKey(product)) {
        throw FactorioException('Cyclical recipes not permitted');
      }
    }
  }

  @override
  void update(Map<ItemData, double> requirements) {
    // TODO
  }

  @override
  Map<ItemData, double> get totalIoPerSecond {
    Map<ItemData, double> io = Map.from(_productsPerSecond);
    _ingredientsPerSecond.forEach((item, amount) => io[item] = -amount);

    return Map.unmodifiable(io);
  }

  void _verifyMachineCompatibility(ModuledMachine newMachine) {
    if (!newMachine.craftingMachine.recipes.contains(qRecipe.recipe)) {
      throw FactorioException(
        'Machine "${newMachine.craftingMachine}" cannot craft recipe "${qRecipe.recipe}"',
      );
    }
  }
}
