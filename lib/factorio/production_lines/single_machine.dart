part of 'production_line.dart';

abstract interface class ProdLineCraftingMachine {
  // TODO: Modules
  double get productivityBonus;
  double get speedBonus;
  double get pollutionBonus;
  double get consumptionBonus;

  double get finalCraftingSpeed;
  double get singleMachineConsumption;
  Map<String, double> get singleMachineEmissions;

  List<DisplayData> get productivityData;
  List<DisplayData> get speedData;
  List<DisplayData> get pollutionData;
  List<DisplayData> get consumptionData;

  // TODO - account for surface
  static ValueAndDisplayData<double> calculateProductivityBonus(
    MachineEntity machine, {
    Surface? surface,
    QualityRecipe? recipe,
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
  static ValueAndDisplayData<double> calculateSpeedBonus(
    MachineEntity machine, {
    Surface? surface,
    QualityRecipe? recipe,
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

  static ValueAndDisplayData<double> calculateConsumptionBonus(
    MachineEntity machine, {
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

  static ValueAndDisplayData<double> calculatePollutionBonus(
    MachineEntity machine, {
    Surface? surface,
    Recipe? recipe,
    ItemEntity? fuel,
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

    if (fuel is SolidItemEntity? &&
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
        .whereType<FluidItemEntity>()
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
}
