part of 'production_line.dart';

class CombinerLine with ProductionLine<ProductionLineIoData> {
  // TODO - combine liquids to get correct temperature range
  final ItemEntity item;

  @override
  String get name => '$item combiner';
  @override
  ProductionLineType get productionLineType => ProductionLineType.combiner;
  @override
  Icon? get icon => item.icon;

  @override
  Set<ItemEntity> get inputItems => _ioItem;
  @override
  Set<ItemEntity> get outputItems => _ioItem;
  @override
  final ItemIoImpl ioRatios;

  final Set<ItemEntity> _ioItem;

  CombinerLine(this.item)
    : _ioItem = Set.unmodifiable({item}),
      ioRatios = ItemIoImpl(inputs: {item: 1.0}, outputs: {item: 1.0});

  @override
  ProductionLineIoData calculateIoData([
    ItemIoImpl constraints = ItemIoImpl.empty,
  ]) {
    verifyConstraints(constraints);

    ItemIoImpl io;
    if (constraints.isZero) {
      io = ioRatios.zeroAllValues();
    } else {
      var amountMap = {
        item: constraints.inputs[item]! > constraints.outputs[item]!
            ? constraints.inputs[item]!
            : constraints.outputs[item]!,
      };

      io = ItemIoImpl(inputs: amountMap, outputs: amountMap);
    }

    return ProductionLineIoData(
      constraints: constraints,
      itemIo: io,
      totalProductionAndConsumption: ItemIoImpl.empty,
    );
  }

  @override
  String toString() => name;
}
