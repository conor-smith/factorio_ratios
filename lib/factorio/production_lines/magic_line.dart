part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class IoLine with ProductionLine<IoLineIoData> {
  @override
  final Set<InGameItem> outputItems;
  @override
  final Set<InGameItem> inputItems;
  @override
  final String name;
  @override
  final List<IconData>? icon;

  @override
  String get type => 'io';
  @override
  bool get isImmutable => true;

  @override
  ItemIo? get outputRatios => null;
  @override
  ItemIo? get inputRatios => null;

  IoLine({
    required this.name,
    Set<InGameItem> netInputs = const {},
    Set<InGameItem> netOutputs = const {},
    this.icon,
  }) : outputItems = Set.unmodifiable(netInputs),
       inputItems = Set.unmodifiable(netOutputs) {
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
      icon = item.icons;

  IoLine.singleItemConsumer(InGameItem item)
    : outputItems = Set.unmodifiable({item}),
      inputItems = const {},
      name = '${item.name} consumer',
      icon = item.icons;

  @override
  IoLineIoData calculate({
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
  }) {
    verifyConstraintsAndIo(inputConstraints, inputConstraints);

    if (inputConstraints.length != outputItems.length ||
        outputConstraints.length != inputItems.length) {
      throw ProductionLineException(
        'Must specify a constraint for every input / output of IO line',
      );
    }

    return IoLineIoData(
      displayData: [
        DisplayData.netOutput(outputConstraints),
        DisplayData.netInput(inputConstraints),
      ],
      netInput: inputConstraints,
      netOutput: outputConstraints,
      inputConstraints: inputConstraints,
      outputConstraints: outputConstraints,
    );
  }
}

class IoLineIoData extends ProductionLineIo {
  IoLineIoData({
    required super.displayData,
    required super.netInput,
    required super.netOutput,
    required super.inputConstraints,
    required super.outputConstraints,
  });
}
