part of 'production_line_node.dart';

abstract class ProdLineNodeState {
  ItemIo? get requirements;

  ProductionLine get productionLine;
  ProductionLineIo? get io;

  NodeGeometryImpl get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;
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
    required super.nodeGeometry,
    required this.io,
  }) : requirements = null,
       super.initial();

  ProdLineNodeStateImpl._(
    ProdLineNode node, {
    this.requirements,
    required this.productionLine,
    required this.io,
    required super.nodeGeometry,
    required super.parents,
    required super.children,
  }) : super(node, productionLine: productionLine) {
    for (var edge in parents.followedBy(children)) {
      if (edge.parentGraph != node.parentGraph) {
        throw NodeException(
          'Edge belonging to parent graph ${edge.parentGraph} cannot be added to node $node',
        );
      }
    }

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

class ProdLineNodeStateBuilder
    extends AbstractNodeStateBuilder<ProdLineNodeStateImpl>
    implements ProdLineNodeState {
  @override
  final ProdLineNode node;

  ItemIo? _requirements;
  ProductionLine _productionLine;
  ProductionLineIo? _io;

  @override
  ItemIo? get requirements => _requirements;
  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIo? get io => _io;

  ProdLineNodeStateBuilder._from(this.node)
    : _requirements = node._state.requirements,
      _productionLine = node._state.productionLine,
      super.from(node);

  @override
  void addSelf() {
    node.parentGraph.getStateBuilder().addProdLineNode(node);
  }

  @override
  void removeSelf() {
    super.removeSelf();

    node.parentGraph.getStateBuilder().removeProdLineNode(node);
  }

  void updateRequirements(ItemIo requirements) => _requirements = requirements;
  void clearRequirements() => _requirements = null;

  void updateProductionLine(ProductionLine newProdLine) {
    // Remove any edges that can no longer connect
    var parentsToRemove = _productionLine.outputItems
        .difference(newProdLine.outputItems)
        .expand(
          (removedOutput) =>
              parents.where((parent) => parent.item == removedOutput),
        );
    var childrenToRemove = _productionLine.inputItems
        .difference(newProdLine.inputItems)
        .expand(
          (removedOutput) =>
              children.where((child) => child.item == removedOutput),
        );

    for (var toRemove in parentsToRemove.followedBy(childrenToRemove)) {
      toRemove.getStateBuilder().removeSelf();
    }

    _productionLine = newProdLine;
  }

  @override
  void clearIo() {
    _io = null;
    clearParentIo();
  }

  @override
  void calculateIo(ItemIo constraints) {
    _io = productionLine.calculate(constraints);
    clearParentIo();
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl._(
    node,
    requirements: _requirements,
    productionLine: _productionLine,
    io: io,
    nodeGeometry: nodeGeometry,
    parents: parents,
    children: children,
  );
}
