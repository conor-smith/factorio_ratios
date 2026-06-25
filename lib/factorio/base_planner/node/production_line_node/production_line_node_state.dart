part of 'production_line_node.dart';

abstract class ProdLineNodeState implements NodeState {
  ItemIo? get requirements;

  ProductionLine get productionLine;
}

class ProdLineNodeStateImpl extends AbstractNodeState
    implements ProdLineNodeState, ToJson {
  @override
  final ItemIo? requirements;

  @override
  final ProductionLine productionLine;

  @override
  final ProductionLineIo? io;

  ProdLineNodeStateImpl._initial({
    required this.productionLine,
    required super.geometry,
    required this.io,
  }) : requirements = null,
       super.initial();

  ProdLineNodeStateImpl(
    ProdLineNode node, {
    this.requirements,
    required this.productionLine,
    required this.io,
    required super.geometry,
    required super.parents,
    required super.children,
  }) : super(node, productionLine: productionLine) {
    switch (node.nodeType) {
      case NodeType.consumer:
        if (productionLine.outputItems.isNotEmpty ||
            productionLine.inputItems.isEmpty) {
          throw NodeException(
            'ProductionLine $productionLine invalid for consumer node',
          );
        } else if (requirements != null &&
            (requirements!.outputs.isNotEmpty ||
                !productionLine.inputItems.containsAll(
                  requirements!.inputs.keys,
                ))) {
          throw NodeException(
            'Requirements $requirements invalid for consumer node $node',
          );
        }

      case NodeType.producer:
        if (productionLine.inputItems.isNotEmpty ||
            productionLine.outputItems.isEmpty) {
          throw NodeException(
            'ProductionLine $productionLine invalid for producer node',
          );
        } else if (requirements != null &&
            (requirements!.inputs.isNotEmpty ||
                !productionLine.outputItems.containsAll(
                  requirements!.inputs.keys,
                ))) {
          throw NodeException(
            'Requirements $requirements invalid for producer node $node',
          );
        }

      case NodeType.combiner:
        if (productionLine is! CombinerLine) {
          throw const NodeException(
            'Production line for combiner node must be CombinerLine',
          );
        }
        continue emptyRequirements;

      emptyRequirements:
      default:
        if (requirements != null) {
          throw NodeException(
            'Cannot set requirements on ${node.nodeType} node',
          );
        }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
