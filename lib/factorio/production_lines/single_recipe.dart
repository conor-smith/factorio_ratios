part of '../production_line.dart';

class SingleRecipeLine extends ProductionLine {
  final ImmutableModuledMachineAndRecipe production;
  double _machineAmount;

  @override
  final Set<ItemData> allInputs;
  @override
  final Set<ItemData> allOutputs;
  final Map<ItemData, double> machineTotalIoPerSecond;

  final Map<ItemData, double> _totalIoPerSecond = {};
  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );

  double get machineAmount => _machineAmount;

  factory SingleRecipeLine(
    ImmutableModuledMachineAndRecipe production, [
    Map<ItemData, double>? initialRequirements,
  ]) {
    Set<ItemData> inputs = {};
    Set<ItemData> outputs = {};
    Map<ItemData, double> machineTotalIoPerSecond = {};

    double cyclesPerSecond =
        production.recipe!.energyRequired / production.totalCraftingSpeed;

    for (var ingredient in production.recipe!.ingredients) {
      machineTotalIoPerSecond[ItemData(ingredient.item)] =
          -ingredient.amount * cyclesPerSecond;
    }

    for (var product in production.recipe!.results) {
      ItemData itemD = ItemData(product.item);
      double netOutput =
          product.amount * product.probability * cyclesPerSecond +
          (machineTotalIoPerSecond[itemD] ?? 0);
      netOutput = netOutput > 0
          ? netOutput * production.totalProductivity
          : netOutput;
      machineTotalIoPerSecond[itemD] = netOutput;
    }

    if (production.fuel != null) {
      ItemData fuel = production.fuel!;
      double fuelPerSecond =
          production.totalEnergyUsage / (fuel.item as SolidItem).fuelValue!;

      machineTotalIoPerSecond.update(
        fuel,
        (amount) => amount - fuelPerSecond,
        ifAbsent: () => -fuelPerSecond,
      );

      if (fuel.item is SolidItem &&
          (fuel.item as SolidItem).burntResult != null) {
        ItemData burntFuel = ItemData((fuel.item as SolidItem).burntResult!);
        machineTotalIoPerSecond.update(
          burntFuel,
          (amount) => amount + fuelPerSecond,
          ifAbsent: () => fuelPerSecond,
        );
      }
    }

    machineTotalIoPerSecond.forEach((itemD, amount) {
      if (amount < 0) {
        inputs.add(itemD);
      } else {
        outputs.add(itemD);
      }
    });

    return SingleRecipeLine._(
      production: production,
      allInputs: Set.unmodifiable(inputs),
      allOutputs: Set.unmodifiable(outputs),
      machineTotalIoPerSecond: Map.unmodifiable(machineTotalIoPerSecond),
      initialRequirements: initialRequirements,
    );
  }

  SingleRecipeLine._({
    required this.production,
    required this.allInputs,
    required this.allOutputs,
    required this.machineTotalIoPerSecond,
    required Map<ItemData, double>? initialRequirements,
  }) : _machineAmount = 1 {
    if (initialRequirements != null) {
      update(initialRequirements);
    }
  }

  @override
  void update(Map<ItemData, double> requirements) {
    super.update(requirements);

    double machinesRequired = 0;
    requirements.forEach((itemD, requiredAmount) {
      if (requiredAmount > 0 && !allOutputs.contains(itemD)) {
        throw FactorioException('Cannot produce item "$itemD"');
      } else if (requiredAmount < 0 && !allInputs.contains(itemD)) {
        throw FactorioException('Cannot consume item "$itemD"');
      }

      double itemMachinesRequired =
          requiredAmount / machineTotalIoPerSecond[itemD]!;
      machinesRequired = machinesRequired > itemMachinesRequired
          ? machinesRequired
          : itemMachinesRequired;
    });

    _machineAmount = machinesRequired;

    machineTotalIoPerSecond.forEach((itemD, amount) {
      _totalIoPerSecond[itemD] = amount * _machineAmount;
    });
  }

  @override
  String toString() {
    return production.recipe!.toString();
  }
}
