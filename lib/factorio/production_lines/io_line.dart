part of 'production_line.dart';

class IoLine implements ProductionLine<IoLineIo> {
  // TODO: launch rockets
  final InGameItem item;

  @override
  final String name;
  @override
  ProductionLineType get productionLineType => ProductionLineType.magic;
  @override
  EntityPrototype get icon => item;

  @override
  Set<InGameItem> get inputItems => _ioItem;
  @override
  Set<InGameItem> get outputItems => _ioItem;
  @override
  final ItemIo ioRatios;

  final Set<InGameItem> _ioItem;

  IoLine.input(InGameItem item)
    : this._simpleIo(item: item, name: '$item input');

  IoLine.output(InGameItem item)
    : this._simpleIo(item: item, name: '$item output');

  IoLine._simpleIo({required this.item, required this.name})
    : _ioItem = Set.unmodifiable({item}),
      ioRatios = ItemIo(inputs: {item: 1.0}, outputs: {item: 1.0});

  @override
  IoLineIo calculate(ItemIo constraints) {
    ProductionLine.verifyConstraints(constraints, this);

    var amountMap = {
      item: constraints.inputs[item]! > constraints.outputs[item]!
          ? constraints.inputs[item]!
          : constraints.outputs[item]!,
    };

    return IoLineIo(
      constraints: constraints,
      io: ItemIo(inputs: amountMap, outputs: amountMap),
    );
  }
}

class IoLineIo extends ProductionLineIo {
  IoLineIo({required super.constraints, required super.io})
    : super(
        totalProductionAndConsumption: ItemIo.empty,
        electricPowerConsumption: 0.0,
        emissions: const {},
        displayData: const [],
      );
}
