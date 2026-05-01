part of 'production_line.dart';

class ProductionLineCraftingMachine {
  // TODO - modules
  CraftingMachineWithQuality _internalMachine;
  Surface? _surface;
  RecipeWithQuality? _recipe;
  InGameItem? _fuel;

  late SingleCraftingMachineIo _machineIo;

  ProductionLineCraftingMachine({
    required CraftingMachineWithQuality machine,
    Surface? surface,
    RecipeWithQuality? recipe,
    InGameItem? fuel,
  }) : _internalMachine = machine,
       _surface = surface,
       _recipe = recipe,
       _fuel = fuel {
    if (!_verifyMachineAndRecipe(_internalMachine, _recipe!)) {
      throw FactorioException(
        'Machine $_internalMachine is incompatible with recipe $_recipe',
      );
    } else if (!_verifyMachineAndFuel(_internalMachine, _fuel!)) {
      throw FactorioException(
        'Machine $_internalMachine is incompatible with fuel $_fuel',
      );
    } else if (!_verifyRecipeAndSurface(_recipe!, _surface!)) {
      throw FactorioException(
        'Recipe $_recipe cannot be crafted on surface $_surface',
      );
    }

    _calculate();
  }

  CraftingMachine get internalMachine => _internalMachine;
  Surface? get surface => _surface;
  RecipeWithQuality? get recipe => _recipe;
  InGameItem? get fuel => _fuel;
  SingleCraftingMachineIo get dataBreakdown => _machineIo;

  void setMachine(CraftingMachineWithQuality newMachine) {
    bool existingFuelValid = _verifyMachineAndFuel(newMachine, _fuel);
    bool existingRecipeValid = _verifyMachineAndRecipe(newMachine, _recipe);

    _internalMachine = newMachine;
    _fuel = existingFuelValid ? _fuel : null;
    _recipe = existingRecipeValid ? _recipe : null;
    _calculate();
  }

  bool verifyAndSetRecipe(RecipeWithQuality newRecipe) {
    bool valid =
        _verifyMachineAndRecipe(_internalMachine, newRecipe) &&
        _verifyRecipeAndSurface(newRecipe, _surface);

    if (valid) {
      _recipe = newRecipe;
      _calculate();
    }

    return valid;
  }

  bool verifyAndSetSurface(Surface newSurface) {
    bool valid = _verifyRecipeAndSurface(_recipe, newSurface);

    if (valid) {
      _surface = newSurface;
      _calculate();
    }

    return valid;
  }

  bool verifyAndSetFuel(InGameItem newFuel) {
    bool valid = _verifyMachineAndFuel(_internalMachine, newFuel);

    if (valid) {
      _fuel = newFuel;
      _calculate();
    }

    return valid;
  }

  void clearRecipe() {
    _recipe = null;
    _calculate();
  }

  void clearSurface() {
    _surface = null;
    _calculate();
  }

  void clearFuel() {
    _fuel = null;
    _calculate();
  }

  bool reset({
    required CraftingMachineWithQuality newMachine,
    Surface? newSurface,
    RecipeWithQuality? newRecipe,
    InGameItem? newFuel,
  }) {
    bool valid =
        _verifyMachineAndRecipe(newMachine, recipe) &&
        _verifyMachineAndFuel(newMachine, newFuel) &&
        _verifyRecipeAndSurface(newRecipe, newSurface);

    if (valid) {
      _internalMachine = newMachine;
      _recipe = newRecipe;
      _fuel = newFuel;
      _surface = newSurface;
      _calculate();
    }

    return valid;
  }

  bool _verifyMachineAndRecipe(
    CraftingMachineWithQuality machine,
    RecipeWithQuality? recipe,
  ) => recipe == null || machine.recipes.contains(recipe.internalRecipe);

  bool _verifyMachineAndFuel(
    CraftingMachineWithQuality machine,
    InGameItem? fuel,
  ) {
    var energySource = machine.energySource;

    if (energySource is BurnerEnergySource) {
      return energySource.fuelItems.contains(fuel?.internalItem);
    } else {
      return true;
    }
  }

  bool _verifyRecipeAndSurface(RecipeWithQuality? recipe, Surface? surface) =>
      recipe == null ||
      surface == null ||
      recipe.internalRecipe.surfaces.contains(surface);

  void _calculate() {}
}

class SingleCraftingMachineIo {
  final double powerConsumption;
  final Map<String, double> pollution;

  final ItemIo recipeInput;
  final ItemIo recipeOutput;
  final ItemIo fuelInput;
  final ItemIo burntOutput;
  final Set<InGameItem> possibleSpoilage;
  final ItemIo netIo;
  final ItemIo netIoRatios;

  final double finalProductivityBonus;
  final double totalProductivityBonus;
  final double maxProductivityBonus;
  final double machineBaseProductivityBonus;

  final double finalSpeedBonus;
  final double totalSpeedBonus;
  final double machineBaseSpeedBonus;

  final double finalPollutionBonus;
  final double totalPollutionBonus;
  final double machineBasePollutionBonus;
  final double recipePollutionBonus;
  final double fuelPollutionBonus;

  final double finalConsumptionBonus;
  final double totalConsumptionBonus;
  final double machineBaseConsumptionBonus;

  SingleCraftingMachineIo({
    required this.finalCraftingSpeed,
    required this.baseCraftingSpeed,
    required this.finalPowerConsumption,
    required this.basePowerConsumption,
    required this.finalPollution,
    required this.basePollution,
    required this.recipesPerSecond,
    required this.recipeInput,
    required this.recipeOutput,
    required this.fuelInput,
    required this.burntOutput,
    required this.possibleSpoilage,
    required this.netIo,
    required this.netIoRatios,
    required this.finalProductivityBonus,
    required this.totalProductivityBonus,
    required this.maxProductivityBonus,
    required this.machineBaseProductivityBonus,
    required this.finalSpeedBonus,
    required this.totalSpeedBonus,
    required this.machineBaseSpeedBonus,
    required this.finalPollutionBonus,
    required this.totalPollutionBonus,
    required this.recipePollutionBonus,
    required this.fuelPollutionBonus,
    required this.machineBasePollutionBonus,
    required this.finalConsumptionBonus,
    required this.totalConsumptionBonus,
    required this.machineBaseConsumptionBonus,
  });
}
