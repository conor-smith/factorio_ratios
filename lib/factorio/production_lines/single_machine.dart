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
  final double finalPowerConsumption;
  final Map<String, double> finalEmissions;

  final List<DisplayData> productivityData;
  final List<DisplayData> speedData;
  final List<DisplayData> pollutionData;
  final List<DisplayData> consumptionData;

  ProductionLineCraftingMachine._({
    required this.craftingMachine,
    required this.productivityBonus,
    required this.speedBonus,
    required this.pollutionBonus,
    required this.consumptionBonus,
    required this.finalCraftingSpeed,
    required Map<String, double> finalEmissions,
    required this.finalPowerConsumption,
    required List<DisplayData> productivityData,
    required List<DisplayData> speedData,
    required List<DisplayData> pollutionData,
    required List<DisplayData> consumptionData,
  }) : finalEmissions = Map.unmodifiable(finalEmissions),
       productivityData = List.unmodifiable(productivityData),
       speedData = List.unmodifiable(speedData),
       pollutionData = List.unmodifiable(speedData),
       consumptionData = List.unmodifiable(consumptionData);

  factory ProductionLineCraftingMachine(InGameMachine machine) {
    var productivityBonus = _calculateFinalProductivityBonus(machine);
    var speedBonus = _calculateFinalSpeedBonus(machine);
    var consumptionBonus = _calculateFinalConsumptionBonus(machine);
    var pollutionBonus = _calculateFinalPollutionBonus(machine);

    var finalEmissions = machine.energySource.emissionsPerMinute.map(
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
      finalPowerConsumption: machine.energyUsage * (1 + consumptionBonus.value),
      finalEmissions: finalEmissions,
      productivityData: productivityBonus.displayData,
      speedData: speedBonus.displayData,
      consumptionData: consumptionBonus.displayData,
      pollutionData: pollutionBonus.displayData,
    );
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is ProductionLineCraftingMachine &&
          craftingMachine == other.craftingMachine;

  @override
  int get hashCode => craftingMachine.hashCode + 10;
}

_ValueAndDisplayData<double> _calculateFinalProductivityBonus(
  InGameMachine machine,
) {
  List<DisplayData> dataList = [];

  var machineBaseProdBonus = machine.effectReceiver.baseEffect.productivity;
  if (machineBaseProdBonus != 0.0) {
    dataList.add(
      DisplayData.keyValuePair(
        DisplayData.iconAndString(machine, 'Base Productivity Bonus'),
        DisplayData.percent(machineBaseProdBonus),
      ),
    );
  }

  if (dataList.isNotEmpty &&
      !machine.allowedEffects.contains(Effects.productivity.name)) {
    return _ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(machine, 'does not allow productivity bonus'),
    ]);
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
    }

    dataList = dataList.reversed.toList();
    return _ValueAndDisplayData(finalProdBonus, dataList);
  }
}

_ValueAndDisplayData<double> _calculateFinalSpeedBonus(InGameMachine machine) {
  List<DisplayData> dataList = [];

  var machineBaseSpeedBonus = machine.effectReceiver.baseEffect.speed;
  if (machineBaseSpeedBonus != 0.0) {
    dataList.add(
      DisplayData.keyValuePair(
        DisplayData.iconAndString(machine, 'Base Speed Bonus'),
        DisplayData.percent(machineBaseSpeedBonus),
      ),
    );
  }

  if (dataList.isNotEmpty &&
      !machine.allowedEffects.contains(Effects.speed.name)) {
    return _ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(machine, 'does not allow speed bonus'),
    ]);
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

    return _ValueAndDisplayData(finalSpeedBonus, dataList);
  }
}

_ValueAndDisplayData<double> _calculateFinalConsumptionBonus(
  InGameMachine machine,
) {
  List<DisplayData> dataList = [];

  var machineBaseConBonus = machine.effectReceiver.baseEffect.consumption;
  if (machineBaseConBonus != 0.0) {
    dataList.add(
      DisplayData.keyValuePair(
        DisplayData.iconAndString(machine, 'Base Consumption Bonus'),
        DisplayData.percent(machineBaseConBonus),
      ),
    );
  }

  if (dataList.isNotEmpty &&
      !machine.allowedEffects.contains(Effects.consumption.name)) {
    return _ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(machine, 'does not allow consumption bonus'),
    ]);
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

    return _ValueAndDisplayData(finalConBonus, dataList);
  }
}

_ValueAndDisplayData<double> _calculateFinalPollutionBonus(
  InGameMachine machine,
) {
  List<DisplayData> dataList = [];

  var machineBasePollBonus = machine.effectReceiver.baseEffect.speed;
  if (machineBasePollBonus != 0.0) {
    dataList.add(
      DisplayData.keyValuePair(
        DisplayData.iconAndString(machine, 'Base Pollution Bonus'),
        DisplayData.percent(machineBasePollBonus),
      ),
    );
  }

  if (dataList.isNotEmpty &&
      !machine.allowedEffects.contains(Effects.pollution.name)) {
    return _ValueAndDisplayData(0.0, [
      DisplayData.iconAndString(machine, 'does not allow pollution bonus'),
    ]);
  } else {
    var totalPollBonus = machineBasePollBonus;

    dataList.add(
      DisplayData.keyValuePair(
        DisplayData.string('Total Pollution Bonus'),
        DisplayData.number(totalPollBonus),
      ),
    );

    var finalPollBonus = totalPollBonus;
    return _ValueAndDisplayData(finalPollBonus, dataList);
  }
}

class _ValueAndDisplayData<T> {
  final T value;
  final List<DisplayData> displayData;

  const _ValueAndDisplayData(this.value, this.displayData);
}
