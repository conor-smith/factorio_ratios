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
  ProductionLineType get productionLineType => ProductionLineType.io;

  @override
  ItemIo? get ioRatios => null;

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
    ProductionLine.verifyConstraints(constraints, this);

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
