part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class IoLine implements ProductionLine<IoLineIoData> {
  @override
  final Set<InGameItem> outputItems;
  @override
  final Set<InGameItem> inputItems;
  @override
  final String name;
  @override
  final EntityPrototype? icon;

  @override
  String get type => 'io';

  @override
  ItemAmounts? get outputRatios => null;
  @override
  ItemAmounts? get inputRatios => null;

  IoLine({
    required this.name,
    Set<InGameItem> netInputs = const {},
    Set<InGameItem> netOutputs = const {},
    this.icon,
  }) : inputItems = Set.unmodifiable(netInputs),
       outputItems = Set.unmodifiable(netOutputs) {
    if (netInputs.isEmpty && netOutputs.isEmpty) {
      throw ProductionLineException('No input or output specified for IO line');
    }

    var itemsInIAndO = netOutputs
        .where((item) => netInputs.contains(item))
        .toList();

    if (itemsInIAndO.isNotEmpty) {
      String itemsString = itemsInIAndO.map((item) => item.name).join(', ');
      throw ProductionLineException(
        'The following items were present in both input and output: $itemsString',
      );
    }
  }

  IoLine.singleItemProducer(InGameItem item)
    : outputItems = const {},
      inputItems = Set.unmodifiable({item}),
      name = '${item.name} producer',
      icon = item;

  IoLine.singleItemConsumer(InGameItem item)
    : outputItems = Set.unmodifiable({item}),
      inputItems = const {},
      name = '${item.name} consumer',
      icon = item;

  @override
  IoLineIoData calculate({
    ItemAmounts inputConstraints = const {},
    ItemAmounts outputConstraints = const {},
  }) {
    // TODO: verify

    if (inputConstraints.length != outputItems.length ||
        outputConstraints.length != inputItems.length) {
      throw ProductionLineException(
        'Must specify a constraint for every input / output of IO line',
      );
    }

    return IoLineIoData(
      netInput: inputConstraints,
      netOutput: outputConstraints,
      inputConstraints: inputConstraints,
      outputConstraints: outputConstraints,
    );
  }
}

class IoLineIoData implements ProductionLineIo {
  @override
  final ItemAmounts inputConstraints;
  @override
  final ItemAmounts outputConstraints;
  @override
  final ItemAmounts netInput;
  @override
  final ItemAmounts netOutput;

  @override
  List<DisplayData> get displayData => const [];
  @override
  ItemAmounts get totalOutput => netOutput;
  @override
  ItemAmounts get totalInput => netInput;
  @override
  double get electricPowerConsumption => 0;
  @override
  Map<String, double> get emissions => const {};

  IoLineIoData({
    required ItemAmounts inputConstraints,
    required ItemAmounts outputConstraints,
    required ItemAmounts netInput,
    required ItemAmounts netOutput,
  }) : inputConstraints = Map.unmodifiable(inputConstraints),
       outputConstraints = Map.unmodifiable(outputConstraints),
       netInput = Map.unmodifiable(netInput),
       netOutput = Map.unmodifiable(netOutput);
}
