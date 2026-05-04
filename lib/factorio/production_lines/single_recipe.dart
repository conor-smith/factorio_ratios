part of 'production_line.dart';

class SingleRecipeLine extends ProductionLineCraftingMachine
    with ProductionLine<SingleRecipeLineIo> {
  final InGameRecipe recipe;
  final Surface? surface;
  final InGameItem? fuel;

  @override
  String get type => 'single_recipe';
  @override
  String get name => recipe.name;
  @override
  List<IconData>? get icon => recipe.icons;
  @override
  bool get isImmutable => true;

  @override
  final Set<InGameItem> outputItems;
  @override
  final Set<InGameItem> inputItems;

  @override
  final ItemIo inputRatios;
  @override
  final ItemIo outputRatios;

  final double machineCyclesPerMinute;

  final ItemIo machineNetInput;
  final ItemIo machineNetOutput;
  final ItemIo machineTotalInput;
  final ItemIo machineTotalOutput;

  final Map<InGameItem, InGameItem> potentialSpoilage;

  factory SingleRecipeLine(
    ProductionLineCraftingMachine plMachine,
    InGameRecipe recipe, {
    Surface? surface,
    InGameItem? fuel,
  }) {
    var craftingMachine = plMachine.craftingMachine;

    if (!craftingMachine.recipes.contains(recipe)) {
      throw ProductionLineException(
        'Recipe $recipe cannot be crafted on machine $craftingMachine',
      );
    } else if (surface != null && !recipe.surfaces.contains(surface)) {
      throw ProductionLineException(
        'Recipe $recipe cannot be crafted on surface $surface',
      );
    } else if (!craftingMachine.needsFuel && fuel != null) {
      throw ProductionLineException(
        'Machine $craftingMachine does not need fuel',
      );
    } else if (craftingMachine.needsFuel && fuel == null) {
      throw ProductionLineException(
        'Machine $craftingMachine needs fuel and was not supplied any',
      );
    } else if (craftingMachine.needsFuel &&
        !craftingMachine.fuelItems.contains(fuel!.internalItem)) {
      throw ProductionLineException(
        'Fuel $fuel is not a valid fuel source for machine $craftingMachine',
      );
    }

    var productivityBonus = _calculateFinalProductivityBonus(
      craftingMachine,
      surface: surface,
      recipe: recipe,
    );
    var speedBonus = _calculateFinalSpeedBonus(
      craftingMachine,
      surface: surface,
      recipe: recipe,
    );
    var consumptionBonus = _calculateFinalConsumptionBonus(
      craftingMachine,
      surface: surface,
      recipe: recipe,
    );
    var pollutionBonus = _calculateFinalPollutionBonus(
      craftingMachine,
      surface: surface,
      recipe: recipe,
      fuel: fuel,
    );

    var finalCraftingSpeed =
        craftingMachine.craftingSpeed * (1 + speedBonus.value);
    var finalPowerConsumption =
        craftingMachine.energyUsage * (1 + consumptionBonus.value);
    // TODO - Determine what pollution applies to each surface
    var finalEmissions = craftingMachine.energySource.emissionsPerMinute.map(
      (pollution, amount) =>
          MapEntry(pollution, amount * (1 + pollutionBonus.value)),
    );

    var cyclesPerMinute = finalCraftingSpeed * 60 / recipe.energyRequired;

    ItemIo machineTotalInput = {};
    for (var ingredient in recipe.ingredients) {
      machineTotalInput[ingredient.item] = ingredient.amount * cyclesPerMinute;
    }
    double fuelConsumed = 0;
    if (fuel != null) {
      fuelConsumed = fuel.fuelValue! * 60 / finalPowerConsumption;
      machineTotalInput.update(
        fuel,
        (amount) => amount + fuelConsumed,
        ifAbsent: () => fuelConsumed,
      );
    }

    ItemIo machineTotalOutput = {};
    for (var product in recipe.results) {
      var amountPerCycle =
          product.amount ?? (product.amountMax! + product.amountMin!) / 2;

      var productivityBonusPerCycle =
          (amountPerCycle - product.ignoredByProductivity) *
          productivityBonus.value;
      if (productivityBonusPerCycle > 0) {
        amountPerCycle += productivityBonusPerCycle;
      }

      amountPerCycle *= product.probability;
      amountPerCycle += product.extraCountFraction;

      machineTotalOutput[product.item] = amountPerCycle * cyclesPerMinute;
    }
    if (fuel is InGameSolidItem? && fuel?.burntResult != null) {
      machineTotalOutput.update(
        fuel!.burntResult!,
        (amount) => amount + fuelConsumed,
        ifAbsent: () => fuelConsumed,
      );
    }

    ItemIo machineNetInputs = Map.from(machineTotalInput);
    ItemIo machineNetOutputs = Map.from(machineTotalOutput);

    machineTotalInput.forEach((item, input) {
      var output = machineTotalOutput[item] ?? 0.0;

      if (output > input) {
        machineNetInputs.remove(item);
        machineNetOutputs[item] = output - input;
      } else if (output > 0) {
        machineNetOutputs.remove(item);
        machineNetInputs[item] = input - output;
      }
    });

    var smallestValue = machineNetInputs.values
        .followedBy(machineNetOutputs.values)
        .reduce((val1, val2) => val1 < val2 ? val1 : val2);

    ItemIo machineNetInputRatios = machineNetInputs.map(
      (item, amount) => MapEntry(item, amount / smallestValue),
    );
    ItemIo machineNetOutputRatios = machineNetOutputs.map(
      (item, amount) => MapEntry(item, amount / smallestValue),
    );

    Map<InGameItem, InGameItem> potentialSpoilage = Map.fromEntries(
      machineNetInputs.keys
          .followedBy(machineNetOutputs.keys)
          .whereType<InGameSolidItem>()
          .where((item) => item.spoilResult != null)
          .map((item) => MapEntry(item, item.spoilResult!)),
    );

    return SingleRecipeLine._(
      craftingMachine: craftingMachine,
      productivityBonus: productivityBonus.value,
      speedBonus: speedBonus.value,
      pollutionBonus: pollutionBonus.value,
      consumptionBonus: consumptionBonus.value,
      finalCraftingSpeed: finalCraftingSpeed,
      singleMachineEmissions: finalEmissions,
      singleMachineConsumption: finalPowerConsumption,
      productivityData: productivityBonus.displayData,
      speedData: speedBonus.displayData,
      pollutionData: pollutionBonus.displayData,
      consumptionData: consumptionBonus.displayData,
      recipe: recipe,
      surface: surface,
      fuel: fuel,
      inputItems: machineNetInputs.keys,
      outputItems: machineNetOutputs.keys,
      inputRatios: machineNetInputRatios,
      outputRatios: machineNetOutputRatios,
      machineCyclesPerMinute: cyclesPerMinute,
      machineNetInput: machineNetInputs,
      machineNetOutput: machineNetOutputs,
      machineTotalInput: machineTotalInput,
      machineTotalOutput: machineTotalOutput,
      potentialSpoilage: potentialSpoilage,
    );
  }

  SingleRecipeLine._({
    required super.craftingMachine,
    required this.recipe,
    required this.surface,
    required this.fuel,
    required super.productivityBonus,
    required super.speedBonus,
    required super.pollutionBonus,
    required super.consumptionBonus,
    required super.finalCraftingSpeed,
    required super.singleMachineEmissions,
    required super.singleMachineConsumption,
    required super.productivityData,
    required super.speedData,
    required super.pollutionData,
    required super.consumptionData,
    required Iterable<InGameItem> inputItems,
    required Iterable<InGameItem> outputItems,
    required ItemIo inputRatios,
    required ItemIo outputRatios,
    required this.machineCyclesPerMinute,
    required ItemIo machineNetInput,
    required ItemIo machineNetOutput,
    required ItemIo machineTotalInput,
    required ItemIo machineTotalOutput,
    required Map<InGameItem, InGameItem> potentialSpoilage,
  }) : outputItems = Set.unmodifiable(inputItems),
       inputItems = Set.unmodifiable(outputItems),
       inputRatios = Map.unmodifiable(inputRatios),
       outputRatios = Map.unmodifiable(outputRatios),
       machineNetInput = Map.unmodifiable(machineNetInput),
       machineNetOutput = Map.unmodifiable(machineNetOutput),
       machineTotalInput = Map.unmodifiable(machineTotalInput),
       machineTotalOutput = Map.unmodifiable(machineTotalOutput),
       potentialSpoilage = Map.unmodifiable(potentialSpoilage),
       super._();

  @override
  SingleRecipeLineIo calculate({
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
  }) {
    verifyConstraintsAndIo(inputConstraints, outputConstraints);

    var machineCount = 0.0;

    inputConstraints.forEach((input, constraint) {
      var newMachineCount = constraint / machineNetInput[input]!;

      if (newMachineCount > machineCount) {
        machineCount = newMachineCount;
      }
    });

    outputConstraints.forEach((output, constraint) {
      var newMachineCount = constraint / machineNetOutput[output]!;

      if (newMachineCount > machineCount) {
        machineCount = newMachineCount;
      }
    });

    var electricPowerConsumption =
        craftingMachine.energySource.type == EnergySourceType.electric
        ? singleMachineConsumption * machineCount
        : 0.0;

    return SingleRecipeLineIo(
      inputConstraints: inputConstraints,
      outputConstraints: outputConstraints,
      machineCount: machineCount,
      totalCyclesPerMinute: machineCyclesPerMinute,
      netInput: _multiplyMap(machineNetInput, machineCount),
      netOutput: _multiplyMap(machineNetOutput, machineCount),
      totalInput: _multiplyMap(machineTotalInput, machineCount),
      totalOutput: _multiplyMap(machineTotalOutput, machineCount),
      electricPowerConsumption: electricPowerConsumption,
      pollution: _multiplyMap(singleMachineEmissions, machineCount),
    );
  }
}

class SingleRecipeLineIo extends ProductionLineIo {
  final double machineCount;
  final double totalCyclesPerMinute;

  final ItemIo totalInput;
  final ItemIo totalOutput;

  SingleRecipeLineIo({
    required super.inputConstraints,
    required super.outputConstraints,
    required this.machineCount,
    required this.totalCyclesPerMinute,
    required super.netInput,
    required super.netOutput,
    required ItemIo totalInput,
    required ItemIo totalOutput,
    required super.electricPowerConsumption,
    required super.pollution,
    super.displayData,
  }) : totalInput = Map.unmodifiable(totalInput),
       totalOutput = Map.unmodifiable(totalOutput);
}

Map<K, double> _multiplyMap<K>(Map<K, double> toMultiply, double multiplier) =>
    toMultiply.map((key, value) => MapEntry(key, value * multiplier));
