part of '../graph.dart';

class InfiniteProducer implements ProductionLine {
  final ItemAmount output;

  @override
  final List<ItemAmount> resultsPerSecond;

  InfiniteProducer._(this.output)
    : resultsPerSecond = List.unmodifiable([output]);

  @override
  List<ItemAmount> get ingredientsPerSecond => const [];
  @override
  List<CraftingMachineAmount> get craftingMachines => const [];

  @override
  List<ItemAmount> get solidFuelPerSecond => const [];
  @override
  List<ItemAmount> get burntOutputPerSecond => const [];
  @override
  List<ItemAmount> get fluidFuelPerSecond => const [];

  @override
  Map<String, double> get emissionsPerMinute => const {};

  @override
  double get electricityW => 0;
  @override
  double get solidFuelW => 0;
  @override
  double get fluidFuelW => 0;
  @override
  double get heatW => 0;
}

class InfiniteConsumer implements ProductionLine{
  final ItemAmount input;

  @override
  final List<ItemAmount> ingredientsPerSecond;

  InfiniteConsumer._(this.input)
    : ingredientsPerSecond = List.unmodifiable([input]);

  @override
  List<ItemAmount> get resultsPerSecond => const [];
  @override
  List<CraftingMachineAmount> get craftingMachines => const [];

  @override
  List<ItemAmount> get solidFuelPerSecond => const [];
  @override
  List<ItemAmount> get burntOutputPerSecond => const [];
  @override
  List<ItemAmount> get fluidFuelPerSecond => const [];

  @override
  Map<String, double> get emissionsPerMinute => const {};

  @override
  double get electricityW => 0;
  @override
  double get solidFuelW => 0;
  @override
  double get fluidFuelW => 0;
  @override
  double get heatW => 0;
}