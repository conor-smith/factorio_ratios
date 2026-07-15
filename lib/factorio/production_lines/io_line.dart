part of 'production_line.dart';

class IoLine with ProductionLine<IoLineIoData> {
  // TODO - Add rocket launch

  final InGameItem ioItem;

  @override
  final String name;
  @override
  Icon? get icon => ioItem.icon;

  @override
  final ItemIoImpl ioRatios;

  @override
  Set<InGameItem> get inputItems => _ioItemSet;
  @override
  Set<InGameItem> get outputItems => _ioItemSet;
  @override
  ProductionLineType get productionLineType => ProductionLineType.io;

  final Set<InGameItem> _ioItemSet;

  IoLine({required this.ioItem})
    : name = '$ioItem IO',
      _ioItemSet = Set.unmodifiable([ioItem]),
      ioRatios = ItemIoImpl(inputs: {ioItem: 1}, outputs: {ioItem: 1});

  @override
  IoLineIoData calculateIoData([ItemIoImpl constraints = ItemIoImpl.empty]) {
    verifyConstraints(constraints);

    double amount;
    if (constraints.isZero) {
      amount = 0;
    } else {
      var requiredInput = constraints.inputs[ioItem]!;
      var requiredOutput = constraints.outputs[ioItem]!;
      amount = requiredInput > requiredOutput ? requiredInput : requiredOutput;
    }

    return IoLineIoData(
      constraints: constraints,
      ioItem: ioItem,
      amount: amount,
    );
  }
}

class IoLineIoData extends ProductionLineIoData {
  IoLineIoData({
    required super.constraints,
    required InGameItem ioItem,
    required double amount,
  }) : super(
         itemIo: ItemIoImpl(
           inputs: {ioItem: amount},
           outputs: {ioItem: amount},
         ),
         totalProductionAndConsumption: ItemIoImpl.empty,
       );

  const IoLineIoData.empty() : super.empty();
}
