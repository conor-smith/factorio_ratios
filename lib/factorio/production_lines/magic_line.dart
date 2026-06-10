part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class MagicLine implements ProductionLine<MagicLineIo> {
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
  ItemIo? get ioRatios => null;

  MagicLine({
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

  MagicLine.singleItemProducer(InGameItem item)
    : outputItems = const {},
      inputItems = Set.unmodifiable({item}),
      name = '${item.name} producer',
      icon = item;

  MagicLine.singleItemConsumer(InGameItem item)
    : outputItems = Set.unmodifiable({item}),
      inputItems = const {},
      name = '${item.name} consumer',
      icon = item;

  @override
  MagicLineIo calculate(ItemIo constraints) {
    if (constraints.inputs.length > inputItems.length ||
        !inputItems.containsAll(constraints.inputs.keys)) {
      throw ProductionLineException(
        'Magic line inputs $inputItems did not match input constraints ${constraints.inputs}',
      );
    } else if (constraints.outputs.length > outputItems.length ||
        !outputItems.containsAll(constraints.outputs.keys)) {
      throw ProductionLineException(
        'Magic line outputs $outputItems did not match input constraints ${constraints.outputs}',
      );
    }

    return MagicLineIo(constraints: constraints);
  }
}

class MagicLineIo extends ProductionLineIo {
  MagicLineIo({required super.constraints})
    : super(
        netIo: constraints,
        totalIo: constraints,
        electricPowerConsumption: 0,
        emissions: const {},
        displayData: const [],
      );
}
