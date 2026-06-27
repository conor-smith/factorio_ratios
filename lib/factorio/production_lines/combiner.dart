part of 'production_line.dart';

class CombinerLine with ProductionLine<ProductionLineIoData> {
  // TODO - combine liquids to get correct temperature range
  final InGameItem item;

  @override
  String get name => '$item combiner';
  @override
  ProductionLineType get productionLineType => ProductionLineType.combiner;
  @override
  Icon? get icon => item.icon;

  @override
  Set<InGameItem> get inputItems => _ioItem;
  @override
  Set<InGameItem> get outputItems => _ioItem;
  @override
  final ItemIoImpl ioRatios;

  final Set<InGameItem> _ioItem;

  CombinerLine(this.item)
    : _ioItem = Set.unmodifiable({item}),
      ioRatios = ItemIoImpl(inputs: {item: 1.0}, outputs: {item: 1.0});

  @override
  ProductionLineIoData calculateIoData([
    ItemIoImpl constraints = ItemIoImpl.empty,
  ]) {
    if (constraints.isEmpty) {
      return const ProductionLineIoData.empty();
    }

    verifyConstraints(constraints);

    var amountMap = {
      item: constraints.inputs[item]! > constraints.outputs[item]!
          ? constraints.inputs[item]!
          : constraints.outputs[item]!,
    };

    return ProductionLineIoData(
      constraints: constraints,
      io: ItemIoImpl(inputs: amountMap, outputs: amountMap),
      totalProductionAndConsumption: ItemIoImpl.empty,
    );
  }

  @override
  String toString() => name;
}
