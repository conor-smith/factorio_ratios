part of '../graph.dart';

class SingleRecipeProductionLine extends ProductionLine {
  final Recipe recipe;

  CraftingMachineAmount _craftingMachine;

  List<ItemAmount> _ingredientsPerSecond = const [];
  List<ItemAmount> _resultsPerSecond = const [];

  Map<String, double> _emissionsPerMinute = const {};

  SingleRecipeProductionLine._(
    this.recipe,
    CraftingMachine craftingMachine,
    GraphCondition condition,
  ) : _craftingMachine = CraftingMachineAmount._(craftingMachine) {
    _update(condition);
  }

  void _update(GraphCondition condition) {
    RecipeItem singleCycleOutput = recipe.results.firstWhere(
      (recipeItem) => recipeItem.item == condition.requiredOutput.item,
    );
    double requiredCycles =
        condition.requiredOutput.amount / singleCycleOutput.amount;

    _ingredientsPerSecond = List.unmodifiable(
      recipe.ingredients.map(
        (recipeItem) => ItemAmount._(
          recipeItem.item,
          amount: recipeItem.amount * requiredCycles,
        ),
      ),
    );
    _resultsPerSecond = List.unmodifiable(
      recipe.results.map(
        (recipeItem) => ItemAmount._(
          recipeItem.item,
          amount: recipeItem.amount * requiredCycles,
        ),
      ),
    );

    double requiredMachines = requiredCycles * recipe.energyRequired;
    _craftingMachine._amount = requiredMachines;

    Map<String, double> modifiablePpm = Map.from(
      _craftingMachine.craftingMachine.energySource.emissionsPerMinute,
    );

    double emissionsMultiplier =
        _craftingMachine.amount *
        recipe.emissionsMultiplier *
        ((_craftingMachine.solidFuelPerSecond?.item as SolidItem?)
                ?.fuelEmissionsMultiplier ??
            1) *
        ingredientsPerSecond
            .where((itemAmount) => itemAmount.item.type == ItemType.fluid)
            .map((amount) => (amount.item as FluidItem).emissionsMultipler)
            .reduce((mul1, mul2) => mul1 * mul2);

    modifiablePpm.updateAll((name, value) => value * emissionsMultiplier);
    _emissionsPerMinute = Map.unmodifiable(modifiablePpm);
  }

  List<ItemAmount> _emptyListIfNull(ItemAmount? itemAmount) {
    if (itemAmount == null) {
      return const [];
    } else {
      return List.unmodifiable([itemAmount]);
    }
  }

  @override
  List<CraftingMachineAmount> get craftingMachines =>
      List.unmodifiable([_craftingMachine]);

  @override
  List<ItemAmount> get ingredientsPerSecond => _ingredientsPerSecond;
  @override
  List<ItemAmount> get resultsPerSecond => _resultsPerSecond;

  @override
  List<ItemAmount> get solidFuelPerSecond =>
      _emptyListIfNull(_craftingMachine.solidFuelPerSecond);
  @override
  List<ItemAmount> get burntOutputPerSecond =>
      _emptyListIfNull(_craftingMachine.burntFuelPerSecond);
  @override
  List<ItemAmount> get fluidFuelPerSecond =>
      _emptyListIfNull(_craftingMachine.fluidFuelPerSecond);
  @override
  Map<String, double> get emissionsPerMinute => _emissionsPerMinute;

  @override
  double get electricityW => _craftingMachine.electricityW;
  @override
  double get fluidFuelW => _craftingMachine.fluidFuelW;
  @override
  double get heatW => _craftingMachine.heatW;
  @override
  double get solidFuelW => _craftingMachine.solidFuelW;
}
