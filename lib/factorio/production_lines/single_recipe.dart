part of 'production_line.dart';

class SingleRecipeLine extends ProductionLineCraftingMachine
    implements ProductionLine<SingleRecipeLineIo> {
  final InGameRecipe recipe;
  final Surface? surface;
  final InGameItem? fuel;

  @override
  String get type => 'single_recipe';
  @override
  String get name => recipe.name;
  @override
  EntityPrototype get icon => recipe;

  @override
  final Set<InGameItem> outputItems;
  @override
  final Set<InGameItem> inputItems;

  @override
  final ItemIo ioRatios;

  final double machineCyclesPerMinute;

  final ItemIo machineNetIo;
  final ItemIo machineTotalIo;

  final Map<InGameItem, InGameItem> potentialSpoilage;

  factory SingleRecipeLine(
    ProductionLineCraftingMachine plMachine,
    InGameRecipe recipe, {
    Surface? surface,
    InGameItem? fuel,
  }) {
    var craftingMachine = plMachine.craftingMachine;

    if (!craftingMachine.recipes.contains(recipe.internalRecipe)) {
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

    ItemAmounts machineTotalInput = {};
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

    ItemAmounts machineTotalOutput = {};
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

    ItemAmounts machineNetInputs = Map.from(machineTotalInput);
    ItemAmounts machineNetOutputs = Map.from(machineTotalOutput);

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

    ItemAmounts machineNetInputRatios = machineNetInputs.map(
      (item, amount) => MapEntry(item, amount / smallestValue),
    );
    ItemAmounts machineNetOutputRatios = machineNetOutputs.map(
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
      ioRatios: ItemIo(
        inputs: machineNetInputRatios,
        outputs: machineNetOutputRatios,
      ),
      machineCyclesPerMinute: cyclesPerMinute,
      machineNetIo: ItemIo(
        inputs: machineNetInputs,
        outputs: machineNetOutputs,
      ),
      machineTotalIo: ItemIo(
        inputs: machineTotalInput,
        outputs: machineTotalOutput,
      ),
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
    required this.machineNetIo,
    required this.machineTotalIo,
    required this.ioRatios,
    required this.machineCyclesPerMinute,
    required Map<InGameItem, InGameItem> potentialSpoilage,
  }) : inputItems = Set.unmodifiable(inputItems),
       outputItems = Set.unmodifiable(outputItems),
       potentialSpoilage = Map.unmodifiable(potentialSpoilage),
       super._();

  @override
  SingleRecipeLineIo calculate(ItemIo constraints) {
    // TODO: verify constraints

    var machineCount = 0.0;

    constraints.inputs.forEach((input, constraint) {
      var newMachineCount = constraint / machineNetIo.inputs[input]!;

      if (newMachineCount > machineCount) {
        machineCount = newMachineCount;
      }
    });

    constraints.outputs.forEach((output, constraint) {
      var newMachineCount = constraint / machineNetIo.outputs[output]!;

      if (newMachineCount > machineCount) {
        machineCount = newMachineCount;
      }
    });

    var electricPowerConsumption =
        craftingMachine.energySource.type == EnergySourceType.electric
        ? singleMachineConsumption * machineCount
        : 0.0;

    return SingleRecipeLineIo(
      constraints: constraints,
      machineCount: machineCount,
      totalCyclesPerMinute: machineCyclesPerMinute,
      netIo: ItemIo(
        inputs: _multiplyMap(machineNetIo.inputs, machineCount),
        outputs: _multiplyMap(machineNetIo.outputs, machineCount),
      ),
      totalIo: ItemIo(
        inputs: _multiplyMap(machineTotalIo.inputs, machineCount),
        outputs: _multiplyMap(machineTotalIo.outputs, machineCount),
      ),
      electricPowerConsumption: electricPowerConsumption,
      emissions: _multiplyMap(singleMachineEmissions, machineCount),
    );
  }
}

class SingleRecipeLineIo extends ProductionLineIo {
  final double machineCount;
  final double totalCyclesPerMinute;

  SingleRecipeLineIo({
    required super.constraints,
    required super.netIo,
    required super.totalIo,
    required super.electricPowerConsumption,
    super.displayData = const [],
    required super.emissions,
    required this.machineCount,
    required this.totalCyclesPerMinute,
  });
}

Map<K, double> _multiplyMap<K>(Map<K, double> toMultiply, double multiplier) =>
    toMultiply.map((key, value) => MapEntry(key, value * multiplier));
