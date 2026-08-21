part of 'production_line.dart';

/// Represents a single machine
class ProdLineCraftingMachineImpl implements ProdLineCraftingMachine {
  // TODO - modules
  final MachineEntity internalMachine;

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

  factory ProdLineCraftingMachineImpl(MachineEntity machine) {
    var productivityBonus = ProdLineCraftingMachine.calculateProductivityBonus(
      machine,
    );
    var speedBonus = ProdLineCraftingMachine.calculateSpeedBonus(machine);
    var consumptionBonus = ProdLineCraftingMachine.calculateConsumptionBonus(
      machine,
    );
    var pollutionBonus = ProdLineCraftingMachine.calculatePollutionBonus(
      machine,
    );

    var emissions = machine.energySource.emissionsPerMinute.map(
      (pollution, amount) =>
          MapEntry(pollution, amount * (1 + pollutionBonus.value)),
    );

    return ProdLineCraftingMachineImpl._(
      internalMachine: machine,
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

  ProdLineCraftingMachineImpl._({
    required this.internalMachine,
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
      (other is ProdLineCraftingMachineImpl &&
          internalMachine == other.internalMachine);

  @override
  int get hashCode => internalMachine.hashCode + 10;

  @override
  String toString() => internalMachine.toString();
}
