part of 'production_line.dart';

/// Represents a single machine
class ProductionLineCraftingMachine {
  // TODO - modules
  CraftingMachineWithQuality _internalMachine;
  Surface? _surface;
  RecipeWithQuality? _recipe;
  InGameItem? _fuel;

  late SingleCraftingMachineIo _machineIo;

  CraftingMachine get internalMachine => _internalMachine;
  Surface? get surface => _surface;
  RecipeWithQuality? get recipe => _recipe;
  InGameItem? get fuel => _fuel;
  SingleCraftingMachineIo get dataBreakdown => _machineIo;

  List<DisplayData> get singleMachineDisplayData => _machineIo.displayData;

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

  // TODO - modules, liquid fuels
  void _calculate() {
    var productivityBonus = _calculateFinalProductivityBonus();
    var speedBonus = _calculateFinalSpeedBonus();
    var consumptionBonus = _calculateFinalConsumptionBonus();
    var pollutionBonus = _calculateFinalPollutionBonus();
  }

  _BonusAndDisplayData _calculateFinalProductivityBonus() {
    List<DisplayData> dataList = [];

    var machineBaseProdBonus =
        _internalMachine.effectReceiver.baseEffect.productivity;
    if (machineBaseProdBonus != 0.0) {
      dataList.add(
        DisplayData.keyValuePair(
          DisplayData.iconAndString(
            _internalMachine,
            'Base Productivity Bonus',
          ),
          DisplayData.percent(machineBaseProdBonus),
        ),
      );
    }

    if (dataList.isEmpty) {
      // No bonus to apply
      return _BonusAndDisplayData(0.0);
    } else if (!_internalMachine.allowedEffects.contains(
      Effects.productivity.name,
    )) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(
          _internalMachine,
          'does not allow productivity bonus',
        ),
      );
    } else if (!(_recipe?.allowProductivity ?? true)) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(
          _recipe!,
          'does not allow productivity bonus',
        ),
      );
    } else {
      var totalProdBonus = machineBaseProdBonus;
      dataList.add(
        DisplayData.keyValuePair(
          DisplayData.string('Total Productivity Bonus'),
          DisplayData.number(totalProdBonus),
        ),
      );

      var finalProdBonus = totalProdBonus;
      if (finalProdBonus < Effects.productivity.minBonus) {
        finalProdBonus = Effects.productivity.minBonus;
        dataList.add(
          DisplayData.keyValuePair(
            DisplayData.string('Minimum Productivity Bonus'),
            DisplayData.percent(finalProdBonus),
          ),
        );
      } else if (_recipe != null &&
          totalProdBonus > _recipe!.maximumProductivity - 1) {
        finalProdBonus = _recipe!.maximumProductivity - 1;
        dataList.add(
          DisplayData.keyValuePair(
            DisplayData.iconAndString(_recipe!, 'Maximum Productivity Bonus'),
            DisplayData.percent(finalProdBonus),
          ),
        );
      }

      dataList = dataList.reversed.toList();
      return _BonusAndDisplayData(
        finalProdBonus,
        DisplayData.keyValuePair(
          DisplayData.string('Productivity Bonus'),
          DisplayData.percent(finalProdBonus),
          dataList,
        ),
      );
    }
  }

  _BonusAndDisplayData _calculateFinalSpeedBonus() {
    List<DisplayData> dataList = [];

    var machineBaseSpeedBonus =
        _internalMachine.effectReceiver.baseEffect.speed;
    if (machineBaseSpeedBonus != 0.0) {
      dataList.add(
        DisplayData.keyValuePair(
          DisplayData.iconAndString(_internalMachine, 'Base Speed Bonus'),
          DisplayData.percent(machineBaseSpeedBonus),
        ),
      );
    }

    if (dataList.isEmpty) {
      // No bonus to apply
      return _BonusAndDisplayData(0.0);
    } else if (!_internalMachine.allowedEffects.contains(Effects.speed.name)) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(
          _internalMachine,
          'does not allow speed bonus',
        ),
      );
    } else if (!(_recipe?.allowSpeed ?? true)) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(_recipe!, 'does not allow speed bonus'),
      );
    } else {
      var totalSpeedBonus = machineBaseSpeedBonus;
      dataList.add(
        DisplayData.keyValuePair(
          DisplayData.string('Total Speed Bonus'),
          DisplayData.number(totalSpeedBonus),
        ),
      );

      var finalSpeedBonus = totalSpeedBonus;
      if (finalSpeedBonus < Effects.speed.minBonus) {
        finalSpeedBonus = Effects.speed.minBonus;
        dataList.add(
          DisplayData.keyValuePair(
            DisplayData.string('Minimum Speed Bonus'),
            DisplayData.percent(finalSpeedBonus),
          ),
        );
      }

      return _BonusAndDisplayData(
        finalSpeedBonus,
        DisplayData.keyValuePair(
          DisplayData.string('Speed Bonus'),
          DisplayData.percent(finalSpeedBonus),
          dataList,
        ),
      );
    }
  }

  _BonusAndDisplayData _calculateFinalConsumptionBonus() {
    List<DisplayData> dataList = [];

    var machineBaseConBonus =
        _internalMachine.effectReceiver.baseEffect.consumption;
    if (machineBaseConBonus != 0.0) {
      dataList.add(
        DisplayData.keyValuePair(
          DisplayData.iconAndString(_internalMachine, 'Base Consumption Bonus'),
          DisplayData.percent(machineBaseConBonus),
        ),
      );
    }

    if (dataList.isEmpty) {
      // No bonus to apply
      return _BonusAndDisplayData(0.0);
    } else if (!_internalMachine.allowedEffects.contains(
      Effects.consumption.name,
    )) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(
          _internalMachine,
          'does not allow consumption bonus',
        ),
      );
    } else if (!(_recipe?.allowConsumption ?? true)) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(_recipe!, 'does not allow consumption bonus'),
      );
    } else {
      var totalConBonus = machineBaseConBonus;
      dataList.add(
        DisplayData.keyValuePair(
          DisplayData.string('Total Consumption Bonus'),
          DisplayData.percent(totalConBonus),
        ),
      );

      var finalConBonus = totalConBonus;
      if (finalConBonus < Effects.consumption.minBonus) {
        finalConBonus = Effects.consumption.minBonus;
        dataList.add(
          DisplayData.keyValuePair(
            DisplayData.string('Minimum Consumption Bonus'),
            DisplayData.percent(finalConBonus),
          ),
        );
      }

      return _BonusAndDisplayData(
        finalConBonus,
        DisplayData.keyValuePair(
          DisplayData.string('Consumption Bonus'),
          DisplayData.percent(finalConBonus),
          dataList,
        ),
      );
    }
  }

  _BonusAndDisplayData _calculateFinalPollutionBonus() {
    List<DisplayData> bonusDataList = [];

    var machineBasePollBonus = _internalMachine.effectReceiver.baseEffect.speed;
    if (machineBasePollBonus != 0.0) {
      bonusDataList.add(
        DisplayData.keyValuePair(
          DisplayData.iconAndString(_internalMachine, 'Base Pollution Bonus'),
          DisplayData.percent(machineBasePollBonus),
        ),
      );
    }

    double fuelPollMultiplier = 1.0;
    var consumedFuel = _fuel;
    if (consumedFuel is SolidItemWithQuality? &&
        (consumedFuel?.fuelEmissionsMultiplier ?? 1.0) != 1.0) {
      fuelPollMultiplier = consumedFuel!.fuelEmissionsMultiplier!;

      bonusDataList.add(
        DisplayData.keyValuePair(
          DisplayData.iconAndString(consumedFuel, 'Fuel Emissions Multiplier'),
          DisplayData.multiplier(fuelPollMultiplier),
        ),
      );
    }

    var fluidInputs = (_recipe?.ingredients ?? const [])
        .map((ingredient) => ingredient.item)
        .toList();
    if (consumedFuel != null && !fluidInputs.contains(consumedFuel)) {
      fluidInputs.add(consumedFuel);
    }

    var fluidInputPollMultipliers =
        fluidInputs
            .whereType<FluidItemWithTemp>()
            .where((fluid) => fluid.emissionsMultiplier != 1.0)
            .toList()
          ..sort();

    bonusDataList.addAll(
      fluidInputPollMultipliers.map(
        (fluid) => DisplayData.keyValuePair(
          DisplayData.iconAndString(fluid, 'Emission Multiplier'),
          DisplayData.multiplier(fluid.emissionsMultiplier),
        ),
      ),
    );

    if (bonusDataList.isEmpty) {
      // No bonus to apply
      return _BonusAndDisplayData(0.0);
    } else if (!_internalMachine.allowedEffects.contains(
      Effects.pollution.name,
    )) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(
          _internalMachine,
          'does not allow pollution bonus',
        ),
      );
    } else if (!(_recipe?.allowPollution ?? true)) {
      return _BonusAndDisplayData(
        0.0,
        DisplayData.iconAndString(_recipe!, 'does not allow pollution bonus'),
      );
    } else {
      var totalPollBonus = machineBasePollBonus;

      bonusDataList.add(
        DisplayData.keyValuePair(
          DisplayData.string('Total Pollution Bonus'),
          DisplayData.number(totalPollBonus),
        ),
      );

      var totalPollMultiplier = fluidInputPollMultipliers
          .map((fluid) => fluid.emissionsMultiplier)
          .followedBy([fuelPollMultiplier])
          .reduce((mul1, mul2) => mul1 * mul2);

      if (totalPollMultiplier != 1.0) {
        bonusDataList.add(
          DisplayData.keyValuePair(
            DisplayData.string('Total Multiplier'),
            DisplayData.multiplier(totalPollMultiplier),
          ),
        );
      }

      var finalPollBonus =
          (totalPollMultiplier * totalPollBonus) + totalPollMultiplier - 1;
      return _BonusAndDisplayData(
        finalPollBonus,
        DisplayData.keyValuePair(
          DisplayData.string('Pollution Bonus'),
          DisplayData.percent(finalPollBonus),
          bonusDataList,
        ),
      );
    }
  }
}

class SingleCraftingMachineIo {
  final double powerConsumption;
  final Map<String, double> pollution;

  final ItemIo recipeInput;
  final ItemIo recipeOutput;
  final ItemIo fuelInput;
  final ItemIo burntOutput;
  final ItemIo netInput;
  final ItemIo netOutput;

  final Set<InGameItem> possibleSpoilage;

  final List<DisplayData> displayData;

  SingleCraftingMachineIo({
    required this.powerConsumption,
    required this.pollution,
    required this.recipeInput,
    required this.recipeOutput,
    required this.fuelInput,
    required this.burntOutput,
    required this.netInput,
    required this.netOutput,
    required this.possibleSpoilage,
    required this.displayData,
  });
}

class _BonusAndDisplayData {
  final double bonus;
  final DisplayData? displayData;

  const _BonusAndDisplayData(this.bonus, [this.displayData]);
}
