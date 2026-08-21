part of 'production_line.dart';

/// Represents a 'magic' line that consumes / produces items at no cost
/// Inputs and outputs are decided at creation and cannot be changed
class MagicLine with ProductionLine<ProductionLineIoData> {
  @override
  final Set<ItemEntity> outputItems;
  @override
  final Set<ItemEntity> inputItems;
  @override
  final String name;
  @override
  final Icon? icon;
  @override
  final ItemIoImpl ioRatios;

  @override
  ProductionLineType get productionLineType => ProductionLineType.io;

  MagicLine.singleItemProducer(ItemEntity item)
    : inputItems = const {},
      outputItems = Set.unmodifiable({item}),
      name = '${item.name} producer',
      icon = item.icon,
      ioRatios = ItemIoImpl(outputs: {item: 1});

  MagicLine.singleItemConsumer(ItemEntity item)
    : inputItems = Set.unmodifiable({item}),
      outputItems = const {},
      name = '${item.name} consumer',
      icon = item.icon,
      ioRatios = ItemIoImpl(inputs: {item: 1});

  @override
  ProductionLineIoData calculateIoData([
    ItemIoImpl constraints = ItemIoImpl.empty,
  ]) {
    verifyConstraints(constraints);

    if (constraints.isZero) {
      return ProductionLineIoData(
        constraints: constraints,
        itemIo: ioRatios.zeroAllValues(),
      );
    } else {
      return ProductionLineIoData(constraints: constraints);
    }
  }
}
