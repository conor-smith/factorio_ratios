part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class IoLine extends ProductionLine<IoLineIoData> {
  @override
  final Set<InGameItem> netInputs;
  @override
  final Set<InGameItem> netOutputs;
  @override
  final String name;
  @override
  final List<IconData>? icon;

  IoLine({
    required this.name,
    Set<InGameItem> netInputs = const {},
    Set<InGameItem> netOutputs = const {},
    this.icon,
  }) : netInputs = Set.unmodifiable(netInputs),
       netOutputs = Set.unmodifiable(netOutputs) {
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
    : netInputs = const {},
      netOutputs = Set.unmodifiable({item}),
      name = '${item.name} producer',
      icon = item.icons;

  IoLine.singleItemConsumer(InGameItem item)
    : netInputs = Set.unmodifiable({item}),
      netOutputs = const {},
      name = '${item.name} consumer',
      icon = item.icons;

  @override
  String get type => 'io';

  @override
  ItemIo? get netOutputRatios => null;
  @override
  ItemIo? get netInputRatios => null;

  @override
  IoLineIoData calculate({
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
  }) {
    verifyConstraintsAndIo(inputConstraints, inputConstraints);

    if (inputConstraints.length != netInputs.length ||
        outputConstraints.length != netOutputs.length) {
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

class IoLineIoData extends ProductionLineIoData {
  IoLineIoData({
    required super.displayData,
    required super.netInput,
    required super.netOutput,
    required super.inputConstraints,
    required super.outputConstraints,
  });
}
