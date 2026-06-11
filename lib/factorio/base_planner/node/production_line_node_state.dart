part of 'node.dart';

abstract class ProdLineNodeState implements ToJson {
  ItemIo? get requirements;

  ProductionLine get productionLine;
  ProductionLineIo? get io;

  NodeGeometry get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;
}

class ProdLineNodeStateImpl implements ProdLineNodeState {
  @override
  final ItemIo? requirements;

  @override
  final ProductionLine productionLine;
  @override
  final ProductionLineIo? io;

  @override
  final NodeGeometry nodeGeometry;

  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  ProdLineNodeStateImpl._({
    this.requirements,
    required this.productionLine,
    this.io,
    this.nodeGeometry = NodeGeometry.uninitialised,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
  }) : parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class ProdLineNodeStateBuilder
    implements NodeStateBuilder<ProdLineNodeStateImpl>, ProdLineNodeState {
  final ProdLineNode _node;

  ItemIo? _requirements;

  ProductionLine _productionLine;

  ProductionLineIo? _io;

  NodeGeometry _nodeGeometry;

  final Set<Edge> _parents;
  final Set<Edge> _children;

  @override
  ItemIo? get requirements => _requirements;

  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIo? get io => _io;

  @override
  NodeGeometry get nodeGeometry => _nodeGeometry;

  @override
  late final Set<Edge> parents = UnmodifiableSetView(parents);
  @override
  late final Set<Edge> children = UnmodifiableSetView(children);

  factory ProdLineNodeStateBuilder._new(ProdLineNode node) {
    var builder = ProdLineNodeStateBuilder._from(node);

    var parentGraphStateBuilder = node.parentGraph.getStateBuilder();
    parentGraphStateBuilder
      ..addNode(node)
      ..clearIo();

    if (node.nodeType == NodeType.output) {
      parentGraphStateBuilder.addOutputItems(node.productionLine.outputItems);
    } else if (node.nodeType == NodeType.input) {
      parentGraphStateBuilder.addInputItems(node.productionLine.inputItems);
    }

    return builder;
  }

  static void _remove(ProdLineNode node) {
    node._basePlanner.getSnapshotBuilder().removeFromSnapshot(node);

    var parentGraphStateBuilder = node.parentGraph.getStateBuilder();
    parentGraphStateBuilder
      ..removeNode(node)
      ..clearIo();

    if (node.nodeType == NodeType.output) {
      parentGraphStateBuilder.removeOutputItems(
        node.productionLine.outputItems,
      );
    } else if (node.nodeType == NodeType.input) {
      parentGraphStateBuilder.removeInputItems(node.productionLine.inputItems);
    }

    for (var edge in [...node.parents, ...node.children]) {
      edge.remove();
    }
  }

  ProdLineNodeStateBuilder._from(this._node)
    : _requirements = _node._state.requirements,
      _productionLine = _node._state.productionLine,
      _io = _node._state.io,
      _nodeGeometry = _node._state.nodeGeometry,
      _parents = Set.from(_node._state.parents),
      _children = Set.from(_node._state.children) {
    _node._basePlanner.getSnapshotBuilder().addToSnapsnot(_node, this);
  }

  void updateRequirements(ItemIo requirements) => _requirements = requirements;

  void clearRequirements() => _requirements = null;

  void updateProductionLineAndClearIo(ProductionLine productionLine) {
    _productionLine = productionLine;
    clearIo();
  }

  void clearIo() {
    if (_io != null) {
      _io = null;
      _node.parentGraph.getStateBuilder().clearIo();
    }
  }

  void calculateIo(ItemIo constraints) {
    _io = productionLine.calculate(constraints);
    _node.parentGraph.getStateBuilder().clearIo();
  }

  void calculateIoFromParentEdges() {
    ItemAmounts inputConstraints = {};
    ItemAmounts outputConstraints = {};

    for (var parent in _parents) {
      var newAmount = parent.amount ?? 0;
      switch (parent.edgeType) {
        case EdgeType.requestItems:
          outputConstraints.update(
            parent.item,
            (amount) => amount + newAmount,
            ifAbsent: () => newAmount,
          );
        case EdgeType.acceptExcess:
          inputConstraints.update(
            parent.item,
            (amount) => amount + newAmount,
            ifAbsent: () => newAmount,
          );
      }

      calculateIo(ItemIo(inputs: inputConstraints, outputs: outputConstraints));
    }
  }

  ItemIo updateChildrenAndReturnUnfulfilledIo() {
    // TODO: optimise
    var io = _io;
    if (io == null) {
      for (var child in _children) {
        child.getStateBuilder().clearAmount();
      }

      return ItemIo();
    } else {
      ItemAmounts consumedOutput = {};
      ItemAmounts providedInput = {};

      for (var parent in _parents) {
        var parentAmount = parent.amount ?? 0;

        switch (parent.edgeType) {
          case EdgeType.requestItems:
            consumedOutput.update(
              parent.item,
              (amount) => amount + parentAmount,
              ifAbsent: () => parentAmount,
            );

          case EdgeType.acceptExcess:
            providedInput.update(
              parent.item,
              (amount) => amount + parentAmount,
              ifAbsent: () => parentAmount,
            );
        }
      }

      var remainingOutput = io.io.outputs.map(
        (item, amount) => MapEntry(item, amount - (consumedOutput[item] ?? 0)),
      );
      var unfulfilledInput = io.io.inputs.map(
        (item, amount) => MapEntry(item, amount - (providedInput[item] ?? 0)),
      );

      Map<InGameItem, Map<EdgeType, List<Edge>>> itemToChildMap = {};
      for (var child in _children) {
        itemToChildMap.update(
          child.item,
          (edgeTypeMap) => edgeTypeMap
            ..update(
              child.edgeType,
              (edges) => edges..add(child),
              ifAbsent: () => [child],
            ),
          ifAbsent: () => {
            child.edgeType: [child],
          },
        );
      }

      remainingOutput.updateAll((item, amount) {
        double totalRemovedOutput = 0;
        List<Edge> acceptExcessEdges =
            itemToChildMap[item]?[EdgeType.acceptExcess] ?? const [];

        for (var aeEdge in acceptExcessEdges) {
          var removedOutput = amount * aeEdge.percentage;
          totalRemovedOutput += removedOutput;
          aeEdge.getStateBuilder().updateAmount(removedOutput);
        }

        return amount - totalRemovedOutput;
      });

      unfulfilledInput.updateAll((item, amount) {
        double totalFulfilledInput = 0;
        List<Edge> requestItemsEdges =
            itemToChildMap[item]?[EdgeType.requestItems] ?? const [];

        for (var riEdge in requestItemsEdges) {
          var fulfilledInput = amount * riEdge.percentage;
          totalFulfilledInput += fulfilledInput;
          riEdge.getStateBuilder().updateAmount(fulfilledInput);
        }

        return amount - totalFulfilledInput;
      });

      return ItemIo(inputs: unfulfilledInput, outputs: remainingOutput);
    }
  }

  @override
  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  void addParent(Edge parent) => _parents.add(parent);
  @override
  void removeParent(Edge parent) => _parents.remove(parent);

  @override
  void addChild(Edge child) => _children.add(child);
  @override
  void removeChild(Edge child) => _children.remove(child);

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl._(
    requirements: _requirements,
    productionLine: _productionLine,
    io: _io,
    nodeGeometry: nodeGeometry,
    parents: _parents,
    children: _children,
  );

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
