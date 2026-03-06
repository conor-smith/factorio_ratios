part of '../production_line.dart';

class SingleRecipeLine extends ProductionLine {
  final ImmutableModuledMachineAndRecipe production;
  double _machineAmount;

  @override
  final Set<ItemData> allInputs;
  @override
  final Set<ItemData> allOutputs;
  @override
  bool get immutableIo => true;

  ItemIo? _requirements;
  ItemIo? _totalIoPerSecond;

  @override
  ItemIo? get requirements => _requirements;
  @override
  ItemIo? get totalIoPerSecond => _totalIoPerSecond;

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
      _requirements = {},
      _machineAmount = 0;

  @override
  void update(ItemIo newRequirements) {
    super.update(newRequirements);

    double machineAmount = 0;

    newRequirements.forEach((itemData, amount) {
      double newMachineAmount = amount / production.totalIoPerSecond[itemData]!;

      if (newMachineAmount > machineAmount) {
        machineAmount = newMachineAmount;
      }
    });

    ItemIo io = {};

    production.totalIoPerSecond.forEach(
      (itemData, amount) => io[itemData] = amount * machineAmount,
    );
    _requirements = Map.unmodifiable(newRequirements);
    _totalIoPerSecond = Map.unmodifiable(io);

    _machineAmount = machineAmount;
  }

  @override
  void reset() {
    _machineAmount = 0;
    _requirements = null;
    _totalIoPerSecond = null;
  }

  @override
  String toString() {
    return production.recipe!.toString();
  }
}
