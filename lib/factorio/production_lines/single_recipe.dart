part of '../production_line.dart';

class SingleRecipeLine extends ProductionLine {
  final ImmutableModuledMachineAndRecipe production;
  double _machineAmount;

  @override
  final Set<ItemData> allInputs;
  @override
  final Set<ItemData> allOutputs;

  final Map<ItemData, double> _totalIoPerSecond;
  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );

  double get machineAmount => _machineAmount;

  SingleRecipeLine(this.production)
    : allInputs = Set.unmodifiable(
        production.totalIoPerSecond.entries
            .where((entry) => entry.value < 0)
            .map((entry) => entry.key),
      ),
      allOutputs = Set.unmodifiable(
        production.totalIoPerSecond.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key),
      ),
      _totalIoPerSecond = {},
      _machineAmount = 0;

  @override
  void update(Map<ItemData, double> requirements) {
    super.update(requirements);

    double machineAmount = 0;

    requirements.forEach((itemData, amount) {
      double newMachineAmount = amount / production.totalIoPerSecond[itemData]!;

      if (newMachineAmount > machineAmount) {
        machineAmount = newMachineAmount;
      }
    });

    production.totalIoPerSecond.forEach(
      (itemData, amount) =>
          _totalIoPerSecond[itemData] = amount * machineAmount,
    );

    _machineAmount = machineAmount;
  }

  @override
  void reset() {
    _machineAmount = 0;
    _totalIoPerSecond.clear();
  }

  @override
  String toString() {
    return production.recipe!.toString();
  }
}
