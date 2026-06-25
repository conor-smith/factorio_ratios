part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class MagicLine with ProductionLine<ProductionLineIo> {
  @override
  final Set<InGameItem> outputItems;
  @override
  final Set<InGameItem> inputItems;
  @override
  final String name;
  @override
  final Icon? icon;
  @override
  final ItemIo ioRatios;

  @override
  ProductionLineType get productionLineType => ProductionLineType.io;

  MagicLine.singleItemProducer(InGameItem item)
    : inputItems = const {},
      outputItems = Set.unmodifiable({item}),
      name = '${item.name} producer',
      icon = item.icon,
      ioRatios = ItemIo(outputs: {item: 1});

  MagicLine.singleItemConsumer(InGameItem item)
    : inputItems = Set.unmodifiable({item}),
      outputItems = const {},
      name = '${item.name} consumer',
      icon = item.icon,
      ioRatios = ItemIo(inputs: {item: 1});

  @override
  ProductionLineIo calculate(ItemIo constraints) {
    if (constraints == ItemIo.empty) {
      return const ProductionLineIo.empty();
    }

    verifyConstraints(constraints);

    return ProductionLineIo(constraints: constraints, io: constraints);
  }
}
