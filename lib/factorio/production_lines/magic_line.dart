part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class IoLine extends ProductionLine<IoLineIoData> {
  @override
  final Set<InGameItem> allInputs;
  @override
  final Set<InGameItem> allOutputs;
  @override
  final String name;
  @override
  final List<IconData>? icon;

  IoLine({
    required this.name,
    Set<InGameItem> allInputs = const {},
    Set<InGameItem> allOutputs = const {},
    this.icon,
  }) : allInputs = Set.unmodifiable(allInputs),
       allOutputs = Set.unmodifiable(allOutputs) {
    if (allInputs.isEmpty && allOutputs.isEmpty) {
      throw ProductionLineException('No input or output specified for IO line');
    }

    var itemsInIAndO = allOutputs
        .where((item) => allInputs.contains(item))
        .toList();

    if (itemsInIAndO.isNotEmpty) {
      String itemsString = itemsInIAndO.map((item) => item.name).join(', ');
      throw ProductionLineException(
        'The following items were present in both input and output: $itemsString',
      );
    }
  }

  IoLine.singleItemProducer(InGameItem item)
    : allInputs = const {},
      allOutputs = Set.unmodifiable({item}),
      name = '${item.name} producer',
      icon = item.icons;

  IoLine.singleItemConsumer(InGameItem item)
    : allInputs = Set.unmodifiable({item}),
      allOutputs = const {},
      name = '${item.name} consumer',
      icon = item.icons;

  @override
  String get type => 'io';

  @override
  ItemIo? get netIoRatios => null;

  @override
  IoLineIoData calculate({
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
  }) {
    verifyConstraintsAndIo(inputConstraints, inputConstraints);

    if (inputConstraints.length != allInputs.length ||
        outputConstraints.length != allOutputs.length) {
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
