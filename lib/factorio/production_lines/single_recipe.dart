part of 'production_line.dart';

class SingleRecipeLine
    with ProductionLine<SingleRecipeLineIoData>
    implements ProdLineCraftingMachine {
  final QualityRecipe recipe;
  final ProdLineCraftingMachineImpl craftingMachine;
  final Surface? surface;
  final ItemEntity? fuel;

  @override
  final double productivityBonus;
  @override
  final double speedBonus;
  @override
  final double pollutionBonus;
  @override
  final double consumptionBonus;

  @override
  final double finalCraftingSpeed;
  @override
  final double singleMachineConsumption;
  @override
  final Map<String, double> singleMachineEmissions;

  @override
  final List<DisplayData> productivityData;
  @override
  final List<DisplayData> speedData;
  @override
  final List<DisplayData> pollutionData;
  @override
  final List<DisplayData> consumptionData;

  @override
  ProductionLineType get productionLineType => ProductionLineType.singleRecipe;
  @override
  String get name => recipe.name;
  @override
  Icon? get icon => recipe.icon;

  @override
  final Set<ItemEntity> outputItems;
  @override
  final Set<ItemEntity> inputItems;

  @override
  final ItemIoImpl ioRatios;

  final double machineCyclesPerMinute;

  final ItemIoImpl machineNetIo;
  final ItemIoImpl machineTotalIo;

  final Map<ItemEntity, ItemEntity> potentialSpoilage;

  factory SingleRecipeLine.fromBaseMachine(
    CraftingMachine machine,
    QualityRecipe recipe, {
    Surface? surface,
    ItemEntity? fuel,
  }) => SingleRecipeLine(
    ProdLineCraftingMachineImpl(MachineEntity(machine)),
    recipe,
    surface: surface,
    fuel: fuel,
  );

  factory SingleRecipeLine(
    ProdLineCraftingMachineImpl plMachine,
    QualityRecipe recipe, {
    Surface? surface,
    ItemEntity? fuel,
  }) {
    var craftingMachine = plMachine.internalMachine;

    if (!craftingMachine.recipes.contains(recipe.internal)) {
      throw ProductionLineException(
        'Recipe $recipe cannot be crafted on machine $craftingMachine',
      );
    } else if (surface != null && !recipe.surfaces.contains(surface)) {
      throw ProductionLineException(
        'Recipe $recipe cannot be crafted on surface $surface',
      );
    } else if (!craftingMachine.needsSolidFuel && fuel != null) {
      throw ProductionLineException(
        'Machine $craftingMachine does not need fuel',
      );
    } else if (craftingMachine.needsSolidFuel && fuel == null) {
      throw ProductionLineException(
        'Machine $craftingMachine needs fuel and was not supplied any',
      );
    } else if (craftingMachine.needsSolidFuel &&
        !craftingMachine.fuelItems.contains(fuel!.internal)) {
      throw ProductionLineException(
        'Fuel $fuel is not a valid fuel source for machine $craftingMachine',
      );
    }

    var productivityBonus = ProdLineCraftingMachine.calculateProductivityBonus(
      craftingMachine,
      surface: surface,
      recipe: recipe,
    );
    var speedBonus = ProdLineCraftingMachine.calculateSpeedBonus(
      craftingMachine,
      surface: surface,
      recipe: recipe,
    );
    var consumptionBonus = ProdLineCraftingMachine.calculateConsumptionBonus(
      craftingMachine,
      surface: surface,
      recipe: recipe,
    );
    var pollutionBonus = ProdLineCraftingMachine.calculatePollutionBonus(
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

      amountPerCycle *= product.independentProbability;
      amountPerCycle += product.extraCountFraction;

      machineTotalOutput[product.item] = amountPerCycle * cyclesPerMinute;
    }
    if (fuel is SolidItemEntity? && fuel?.burntResult != null) {
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

    var machineNetIo = ItemIoImpl(
      inputs: machineNetInputs,
      outputs: machineNetOutputs,
    );

    var ioRatios = machineNetIo.convertToRatios();

    Map<ItemEntity, ItemEntity> potentialSpoilage = Map.fromEntries(
      machineNetInputs.keys
          .followedBy(machineNetOutputs.keys)
          .whereType<SolidItemEntity>()
          .where((item) => item.spoilResult != null)
          .map((item) => MapEntry(item, item.spoilResult!)),
    );

    return SingleRecipeLine._(
      craftingMachine: plMachine,
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
      ioRatios: ioRatios,
      machineCyclesPerMinute: cyclesPerMinute,
      machineNetIo: machineNetIo,
      machineTotalIo: ItemIoImpl(
        inputs: machineTotalInput,
        outputs: machineTotalOutput,
      ),
      potentialSpoilage: potentialSpoilage,
    );
  }

  SingleRecipeLine._({
    required this.craftingMachine,
    required this.recipe,
    required this.surface,
    required this.fuel,
    required this.productivityBonus,
    required this.speedBonus,
    required this.pollutionBonus,
    required this.consumptionBonus,
    required this.finalCraftingSpeed,
    required Map<String, double> singleMachineEmissions,
    required this.singleMachineConsumption,
    required List<DisplayData> productivityData,
    required List<DisplayData> speedData,
    required List<DisplayData> pollutionData,
    required List<DisplayData> consumptionData,
    required Iterable<ItemEntity> inputItems,
    required Iterable<ItemEntity> outputItems,
    required this.machineNetIo,
    required this.machineTotalIo,
    required this.ioRatios,
    required this.machineCyclesPerMinute,
    required Map<ItemEntity, ItemEntity> potentialSpoilage,
  }) : inputItems = Set.unmodifiable(inputItems),
       outputItems = Set.unmodifiable(outputItems),
       potentialSpoilage = Map.unmodifiable(potentialSpoilage),
       singleMachineEmissions = Map.unmodifiable(singleMachineEmissions),
       productivityData = List.unmodifiable(productivityData),
       speedData = List.unmodifiable(speedData),
       pollutionData = List.unmodifiable(speedData),
       consumptionData = List.unmodifiable(consumptionData);

  @override
  SingleRecipeLineIoData calculateIoData([
    ItemIoImpl constraints = ItemIoImpl.empty,
  ]) {
    verifyConstraints(constraints);

    if (constraints.isZero) {
      return SingleRecipeLineIoData.zeroConstraints(constraints, ioRatios);
    }

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
        craftingMachine.internalMachine.energySource.type ==
            EnergySourceType.electric
        ? singleMachineConsumption * machineCount
        : 0.0;

    return SingleRecipeLineIoData(
      constraints: constraints,
      machineCount: machineCount,
      totalCyclesPerMinute: machineCyclesPerMinute,
      itemIo: ItemIoImpl(
        inputs: multiplyMap(machineNetIo.inputs, machineCount),
        outputs: multiplyMap(machineNetIo.outputs, machineCount),
      ),
      totalProductionAndConsumption: ItemIoImpl(
        inputs: multiplyMap(machineTotalIo.inputs, machineCount),
        outputs: multiplyMap(machineTotalIo.outputs, machineCount),
      ),
      electricPowerConsumption: electricPowerConsumption,
      emissions: multiplyMap(singleMachineEmissions, machineCount),
    );
  }
}

class SingleRecipeLineIoData extends ProductionLineIoData {
  final double machineCount;
  final double totalCyclesPerMinute;

  SingleRecipeLineIoData({
    required super.constraints,
    required super.itemIo,
    required super.totalProductionAndConsumption,
    required super.electricPowerConsumption,
    super.displayData = const [],
    required super.emissions,
    required this.machineCount,
    required this.totalCyclesPerMinute,
  });

  SingleRecipeLineIoData.zeroConstraints(
    ItemIoImpl constraints,
    ItemIoImpl ioRatios,
  ) : this(
        constraints: constraints,
        itemIo: ioRatios.zeroAllValues(),
        totalProductionAndConsumption: ioRatios.zeroAllValues(),
        electricPowerConsumption: 0,
        emissions: const {},
        machineCount: 0,
        totalCyclesPerMinute: 0,
      );
}
