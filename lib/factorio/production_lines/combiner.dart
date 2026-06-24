part of 'production_line.dart';

class CombinerLine with ProductionLine<CombinerIo> {
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
  final ItemIo ioRatios;

  final Set<InGameItem> _ioItem;

  CombinerLine(this.item)
    : _ioItem = Set.unmodifiable({item}),
      ioRatios = ItemIo(inputs: {item: 1.0}, outputs: {item: 1.0});

  @override
  CombinerIo calculate(ItemIo constraints) {
    verifyConstraints(constraints);

    var amountMap = {
      item: constraints.inputs[item]! > constraints.outputs[item]!
          ? constraints.inputs[item]!
          : constraints.outputs[item]!,
    };

    return CombinerIo(
      constraints: constraints,
      io: ItemIo(inputs: amountMap, outputs: amountMap),
    );
  }

  @override
  String toString() => name;
}

class CombinerIo extends ProductionLineIo {
  CombinerIo({required super.constraints, required super.io})
    : super(
        totalProductionAndConsumption: ItemIo.empty,
        electricPowerConsumption: 0.0,
        emissions: const {},
        displayData: const [],
      );
}
