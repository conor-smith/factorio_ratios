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
  final Set<InGameItem> netInputs;
  @override
  final Set<InGameItem> netOutputs;

  @override
  final ItemIo netInputRatios;
  @override
  final ItemIo netOutputRatios;

  final double cyclesPerMinute;

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
          product.amount ?? ((product.amountMax! + product.amountMin!) / 2);

      var productivityBonusPerCycle =
          (amountPerCycle - product.ignoredByProductivity) *
          productivityBonus.value;
      amountPerCycle += productivityBonusPerCycle > 0
          ? productivityBonusPerCycle
          : 0;

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
      finalEmissions: finalEmissions,
      finalPowerConsumption: finalPowerConsumption,
      productivityData: productivityBonus.displayData,
      speedData: speedBonus.displayData,
      pollutionData: pollutionBonus.displayData,
      consumptionData: consumptionBonus.displayData,
      recipe: recipe,
      surface: surface,
      fuel: fuel,
      netInputs: machineNetInputs.keys,
      netOutputs: machineNetOutputs.keys,
      netInputRatios: machineNetInputRatios,
      netOutputRatios: machineNetOutputRatios,
      cyclesPerMinute: cyclesPerMinute,
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
    required super.finalEmissions,
    required super.finalPowerConsumption,
    required super.productivityData,
    required super.speedData,
    required super.pollutionData,
    required super.consumptionData,
    required Iterable<InGameItem> netInputs,
    required Iterable<InGameItem> netOutputs,
    required ItemIo netInputRatios,
    required ItemIo netOutputRatios,
    required this.cyclesPerMinute,
    required ItemIo machineNetInput,
    required ItemIo machineNetOutput,
    required ItemIo machineTotalInput,
    required ItemIo machineTotalOutput,
    required Map<InGameItem, InGameItem> potentialSpoilage,
  }) : netInputs = Set.unmodifiable(netInputs),
       netOutputs = Set.unmodifiable(netOutputs),
       netInputRatios = Map.unmodifiable(netInputRatios),
       netOutputRatios = Map.unmodifiable(netOutputRatios),
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
    // TODO: implement calculate
    throw UnimplementedError();
  }
}

class SingleRecipeLineIo extends ProductionLineIoData {
  final double machineCount;

  final ItemIo totalInput;
  final ItemIo totalOutput;
  final Set<InGameItem> potentialSpoilage;

  SingleRecipeLineIo({
    required super.inputConstraints,
    required super.outputConstraints,
    required this.machineCount,
    required super.netInput,
    required super.netOutput,
    required ItemIo totalInput,
    required ItemIo totalOutput,
    required Set<InGameItem> potentialSpoilage,
    required super.electricPowerConsumption,
    required super.pollution,
    required super.displayData,
  }) : totalInput = Map.unmodifiable(totalInput),
       totalOutput = Map.unmodifiable(totalOutput),
       potentialSpoilage = Set.unmodifiable(potentialSpoilage);
}
