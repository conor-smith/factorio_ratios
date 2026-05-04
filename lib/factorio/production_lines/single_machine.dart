part of 'production_line.dart';

/// Represents a single machine
class ProductionLineCraftingMachine {
  // TODO - modules
  final InGameMachine craftingMachine;

  final double productivityBonus;
  final double speedBonus;
  final double pollutionBonus;
  final double consumptionBonus;

  final double finalCraftingSpeed;
  final double singleMachineConsumption;
  final Map<String, double> singleMachineEmissions;

  final List<DisplayData> productivityData;
  final List<DisplayData> speedData;
  final List<DisplayData> pollutionData;
  final List<DisplayData> consumptionData;

  factory ProductionLineCraftingMachine(InGameMachine machine) {
    var productivityBonus = _calculateFinalProductivityBonus(machine);
    var speedBonus = _calculateFinalSpeedBonus(machine);
    var consumptionBonus = _calculateFinalConsumptionBonus(machine);
    var pollutionBonus = _calculateFinalPollutionBonus(machine);

    var emissions = machine.energySource.emissionsPerMinute.map(
      (pollution, amount) =>
          MapEntry(pollution, amount * (1 + pollutionBonus.value)),
    );

    return ProductionLineCraftingMachine._(
      craftingMachine: machine,
      productivityBonus: productivityBonus.value,
      speedBonus: speedBonus.value,
      consumptionBonus: consumptionBonus.value,
      pollutionBonus: pollutionBonus.value,
      finalCraftingSpeed: machine.craftingSpeed * (1 + speedBonus.value),
      singleMachineConsumption:
          machine.energyUsage * (1 + consumptionBonus.value),
      singleMachineEmissions: emissions,
      productivityData: productivityBonus.displayData,
      speedData: speedBonus.displayData,
      consumptionData: consumptionBonus.displayData,
      pollutionData: pollutionBonus.displayData,
    );
  }

  ProductionLineCraftingMachine._({
    required this.craftingMachine,
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
  }) : singleMachineEmissions = Map.unmodifiable(singleMachineEmissions),
       productivityData = List.unmodifiable(productivityData),
       speedData = List.unmodifiable(speedData),
       pollutionData = List.unmodifiable(speedData),
       consumptionData = List.unmodifiable(consumptionData);

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is ProductionLineCraftingMachine &&
          craftingMachine == other.craftingMachine;

  @override
  int get hashCode => craftingMachine.hashCode + 10;

  @override
  String toString() => craftingMachine.toString();
}

// TODO - account for surface
ValueAndDisplayData<double> _calculateFinalProductivityBonus(
  InGameMachine machine, {
  Surface? surface,
  InGameRecipe? recipe,
}) {
  double totalBonus = 0.0;
  List<DisplayData> dataList = [];

  var machineBaseProdBonus = machine.effectReceiver.baseEffect.productivity;
  if (machineBaseProdBonus != 0.0) {
    totalBonus += machineBaseProdBonus;

    dataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.iconAndString(
          icon: machine,
          string: 'Base Productivity Bonus',
        ),
        value: DisplayData.percent(machineBaseProdBonus),
      ),
    );
  }

  if (dataList.isEmpty) {
    return ValueAndDisplayData(0.0, const []);
  } else if (!machine.allowedEffects.contains(Effects.productivity.name)) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: machine,
        string: 'does not allow productivity bonus',
      ),
    ]);
  } else if (recipe != null && !recipe.allowProductivity) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: recipe,
        string: 'does not allow productivity bonus',
      ),
    ]);
  } else {
    dataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.string('Total Productivity Bonus'),
        value: DisplayData.percent(totalBonus),
      ),
    );

    var finalProdBonus = totalBonus;
    if (finalProdBonus < Effects.productivity.minBonus) {
      finalProdBonus = Effects.productivity.minBonus;
      dataList.add(
        DisplayData.keyValuePair(
          key: DisplayData.string('Minimum Productivity Bonus'),
          value: DisplayData.percent(finalProdBonus),
        ),
      );
    }

    dataList = dataList.reversed.toList();
    return ValueAndDisplayData(finalProdBonus, dataList);
  }
}

// TODO - account for surface
ValueAndDisplayData<double> _calculateFinalSpeedBonus(
  InGameMachine machine, {
  Surface? surface,
  InGameRecipe? recipe,
}) {
  var totalBonus = 0.0;
  List<DisplayData> dataList = [];

  var machineBaseSpeedBonus = machine.effectReceiver.baseEffect.speed;
  if (machineBaseSpeedBonus != 0.0) {
    totalBonus += machineBaseSpeedBonus;

    dataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.iconAndString(
          icon: machine,
          string: 'Base Speed Bonus',
        ),
        value: DisplayData.percent(machineBaseSpeedBonus),
      ),
    );
  }

  if (dataList.isEmpty) {
    return ValueAndDisplayData(0.0, const []);
  } else if (!machine.allowedEffects.contains(Effects.speed.name)) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: machine,
        string: 'does not allow speed bonus',
      ),
    ]);
  } else if (recipe != null && !recipe.allowSpeed) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: recipe,
        string: 'does not allow speed bonus',
      ),
    ]);
  } else {
    dataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.string('Total Speed Bonus'),
        value: DisplayData.percent(totalBonus),
      ),
    );

    var finalSpeedBonus = totalBonus;
    if (finalSpeedBonus < Effects.speed.minBonus) {
      finalSpeedBonus = Effects.speed.minBonus;
      dataList.add(
        DisplayData.keyValuePair(
          key: DisplayData.string('Minimum Speed Bonus'),
          value: DisplayData.percent(finalSpeedBonus),
        ),
      );
    }

    return ValueAndDisplayData(finalSpeedBonus, dataList);
  }
}

ValueAndDisplayData<double> _calculateFinalConsumptionBonus(
  InGameMachine machine, {
  Surface? surface,
  Recipe? recipe,
}) {
  var totalBonus = 0.0;
  List<DisplayData> dataList = [];

  var machineBaseConBonus = machine.effectReceiver.baseEffect.consumption;
  if (machineBaseConBonus != 0.0) {
    totalBonus += machineBaseConBonus;

    dataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.iconAndString(
          icon: machine,
          string: 'Base Consumption Bonus',
        ),
        value: DisplayData.percent(machineBaseConBonus),
      ),
    );
  }

  if (dataList.isEmpty) {
    return ValueAndDisplayData(0.0, const []);
  } else if (!machine.allowedEffects.contains(Effects.consumption.name)) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: machine,
        string: 'does not allow consumption bonus',
      ),
    ]);
  } else if (recipe != null && !recipe.allowConsumption) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: recipe,
        string: 'does not allow consumption bonus',
      ),
    ]);
  } else {
    dataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.string('Total Consumption Bonus'),
        value: DisplayData.percent(totalBonus),
      ),
    );

    var finalConBonus = totalBonus;
    if (finalConBonus < Effects.consumption.minBonus) {
      finalConBonus = Effects.consumption.minBonus;
      dataList.add(
        DisplayData.keyValuePair(
          key: DisplayData.string('Minimum Consumption Bonus'),
          value: DisplayData.percent(finalConBonus),
        ),
      );
    }

    return ValueAndDisplayData(finalConBonus, dataList);
  }
}

ValueAndDisplayData<double> _calculateFinalPollutionBonus(
  InGameMachine machine, {
  Surface? surface,
  Recipe? recipe,
  InGameItem? fuel,
}) {
  var totalBonus = 0.0;
  var multiplierProduct = 1.0;

  List<DisplayData> bonusDataList = [];
  List<DisplayData> multiplierDataList = [];

  var machineBasePollBonus = machine.effectReceiver.baseEffect.speed;
  if (machineBasePollBonus != 0.0) {
    totalBonus += machineBasePollBonus;

    bonusDataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.iconAndString(
          icon: machine,
          string: 'Base Pollution Bonus',
        ),
        value: DisplayData.percent(machineBasePollBonus),
      ),
    );
  }

  if (fuel is InGameSolidItem? &&
      (fuel?.fuelEmissionsMultiplier ?? 1.0) != 1.0) {
    var fuelEmissionsMultiplier = fuel!.fuelEmissionsMultiplier!;
    multiplierProduct *= fuelEmissionsMultiplier;

    multiplierDataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.iconAndString(
          icon: fuel,
          string: 'Fuel Emission Multiplier',
        ),
        value: DisplayData.multiplier(fuelEmissionsMultiplier),
      ),
    );
  }

  var multiplierFluids = (recipe?.ingredients ?? const [])
      .map((ingredient) => ingredient.item)
      .followedBy([fuel].nonNulls)
      .whereType<InGameFluidItem>()
      .where((fluid) => fluid.emissionsMultiplier != 1.0)
      .toSet();
  if (multiplierFluids.isNotEmpty) {
    var fluidEmissionsMultiplier = multiplierFluids.fold(
      1.0,
      (multiplier, fluid) => multiplier * fluid.emissionsMultiplier,
    );
    multiplierProduct *= fluidEmissionsMultiplier;

    var sortedFluids = multiplierFluids.toList()..sort();
    multiplierDataList.add(
      DisplayData.keyValuePair(
        key: DisplayData.string('Input Emission Multipliers'),
        value: DisplayData.rowAlignedRight([
          DisplayData.string('Product:'),
          DisplayData.multiplier(fluidEmissionsMultiplier),
        ]),
        children: sortedFluids.map(
          (fluid) => DisplayData.keyValuePair(
            key: DisplayData.icon(fluid),
            value: DisplayData.multiplier(fluid.emissionsMultiplier),
          ),
        ),
      ),
    );
  }

  if (bonusDataList.isEmpty && multiplierDataList.isEmpty) {
    return ValueAndDisplayData(0.0, const []);
  } else if (!machine.allowedEffects.contains(Effects.pollution.name)) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: machine,
        string: 'does not allow pollution bonus',
      ),
    ]);
  } else if (recipe != null && !recipe.allowPollution) {
    return ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(
        icon: recipe,
        string: 'does not allow pollution bonus',
      ),
    ]);
  } else {
    var finalDataList = [];

    if (multiplierDataList.isNotEmpty) {
      finalDataList.add(
        DisplayData.keyValuePair(
          key: DisplayData.string('Pollution Multiplier Product'),
          value: DisplayData.multiplier(multiplierProduct),
          children: multiplierDataList,
        ),
      );
    }

    if (bonusDataList.isNotEmpty) {
      finalDataList.add(
        DisplayData.keyValuePair(
          key: DisplayData.string('Total Pollution Bonus'),
          value: DisplayData.percent(totalBonus),
          children: bonusDataList,
        ),
      );
    }

    var finalPollBonus =
        (totalBonus * multiplierProduct) + multiplierProduct - 1;
    return ValueAndDisplayData(finalPollBonus, bonusDataList);
  }
}
