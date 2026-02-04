part of '../production_line.dart';

class SingleRecipeLine extends BasicUpdateable implements ProductionLine {
  QualityRecipe _recipe;
  _ModuledMachineWrapper _moduledMachine;
  bool _recipeOrMachineUpdate;

  SingleRecipeLine._(
    this._recipe,
    ModuledMachine machine,
    Map<ItemData, double> initialConditions,
  ) : _recipeOrMachineUpdate = true,
      _moduledMachine = _ModuledMachineWrapper(machine),
      super(initialConditions) {
    _verifyRecipeAndMachine();
    _moduledMachine._parentLine = this;
    update();
  }

  void _verifyRecipeAndMachine({
    QualityRecipe? newRecipe,
    CraftingMachine? newMachine,
  }) {
    QualityRecipe recipe = newRecipe ?? _recipe;
    CraftingMachine machine = newMachine ?? _moduledMachine.craftingMachine;
    // TODO
  }

  @override
  bool get awaitingUpdate => _recipeOrMachineUpdate || super.awaitingUpdate;

  @override
  void update() {
    if(this.awaitingUpdate) {
      // TODO
      super.update();
    }
  }

  @override
  Map<ItemData, double> get ioPerSecond => throw UnimplementedError();
}

class _ModuledMachineWrapper implements ModuledMachine {
  final ModuledMachine _moduledMachine;
  late final SingleRecipeLine _parentLine;

  _ModuledMachineWrapper(this._moduledMachine);

  @override
  CraftingMachine get craftingMachine => _moduledMachine.craftingMachine;
  @override
  set craftingMachine(CraftingMachine newMachine) {
    _parentLine._verifyRecipeAndMachine(newMachine: newMachine);
    _moduledMachine.craftingMachine = newMachine;
  }
}