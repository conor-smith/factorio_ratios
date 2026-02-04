part of '../production_line.dart';

class SingleRecipeLine extends BasicUpdateable implements ProductionLine {
  QualityRecipe _recipe;
  ModuledMachine _moduledMachine;
  bool _recipeOrMachineUpdate;

  SingleRecipeLine._(
    this._recipe,
    this._moduledMachine,
    Map<ItemData, double> initialConditions,
  ) : _recipeOrMachineUpdate = true,
      super(initialConditions) {
    _verifyRecipeAndMachine();
    update();
  }

  void _verifyRecipeAndMachine({
    QualityRecipe? newRecipe,
    ModuledMachine? newMachine,
  }) {
    QualityRecipe recipe = newRecipe ?? _recipe;
    ModuledMachine machine = newMachine ?? _moduledMachine;
    // TODO
  }

  @override
  bool get awaitingUpdate => _recipeOrMachineUpdate || _moduledMachine.awaitingUpdate || super.awaitingUpdate;

  @override
  void update() {
    if(this.awaitingUpdate) {
      // TODO
      super.update();
    }
  }

  @override
  Map<ItemData, double> get ioPerSecond => throw UnimplementedError();
  @override
  ProductionLineType get type => throw UnimplementedError();
}
