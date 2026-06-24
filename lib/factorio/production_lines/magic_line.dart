part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class MagicLine with ProductionLine<MagicLineIo> {
  @override
  final Set<InGameItem> outputItems;
  @override
  final Set<InGameItem> inputItems;
  @override
  final String name;
  @override
  final Icon? icon;

  @override
  ProductionLineType get productionLineType => ProductionLineType.io;

  @override
  ItemIo? get ioRatios => null;

  MagicLine.singleItemProducer(InGameItem item)
    : inputItems = const {},
      outputItems = Set.unmodifiable({item}),
      name = '${item.name} producer',
      icon = item.icon;

  MagicLine.singleItemConsumer(InGameItem item)
    : inputItems = Set.unmodifiable({item}),
      outputItems = const {},
      name = '${item.name} consumer',
      icon = item.icon;

  @override
  MagicLineIo calculate(ItemIo constraints) {
    verifyConstraints(constraints);

    return MagicLineIo(constraints: constraints);
  }
}

class MagicLineIo extends ProductionLineIo {
  MagicLineIo({required super.constraints})
    : super(
        io: constraints,
        totalProductionAndConsumption: constraints,
        electricPowerConsumption: 0,
        emissions: const {},
        displayData: const [],
      );
}
