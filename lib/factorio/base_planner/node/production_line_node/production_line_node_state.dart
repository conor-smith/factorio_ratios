part of 'production_line_node.dart';

abstract class ProdLineNodeState {
  ItemIo? get requirements;

  ProductionLine get productionLine;
  ProductionLineIo? get io;

  NodeGeometryImpl get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;
}

class ProdLineNodeStateImpl implements ProdLineNodeState, ToJson {
  @override
  final ItemIo? requirements;

  @override
  final ProductionLine productionLine;
  @override
  final ProductionLineIo? io;

  @override
  final NodeGeometryImpl nodeGeometry;

  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  ProdLineNodeStateImpl._initial({
    required this.productionLine,
    required this.nodeGeometry,
  }) : requirements = null,
       io = null,
       parents = const {},
       children = const {};

  ProdLineNodeStateImpl._(
    ProdLineNode node, {
    this.requirements,
    required this.productionLine,
    required this.io,
    required this.nodeGeometry,
    required Iterable<Edge> parents,
    required Iterable<Edge> children,
  }) : parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children) {
    Map<InGameItem, double> excessOutputPercentages = {};

    for (var parent in this.parents) {
      if (parent.child != node) {
        throw NodeException('Edge $parent is not a parent of node $node');
      }
      if (!productionLine.outputItems.contains(parent.item)) {
        throw NodeException('Node $node cannot produce item ${parent.item}');
      }
      if (parent.edgeType == EdgeType.pushExcess) {
        excessOutputPercentages.update(
          parent.item,
          (percentage) => percentage + parent.percentage,
          ifAbsent: () => 0.0,
        );
      }
    }

    excessOutputPercentages.forEach((item, totalPercentage) {
      // Round up to lowest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node pushExcess edges for item $item percentage sum == $totalPercentage',
        );
      }
    });

    Map<InGameItem, double> requestInputPercentages = {};

    for (var child in this.children) {
      if (child.parent != node) {
        throw NodeException('Edge $child is not a parent of node $node');
      }
      if (!productionLine.inputItems.contains(child.item)) {
        throw NodeException('Node $node cannot consume item ${child.item}');
      }
      if (child.edgeType == EdgeType.requestItems) {
        requestInputPercentages.update(
          child.item,
          (percentage) => percentage + child.percentage,
          ifAbsent: () => 0.0,
        );
      }
    }

    requestInputPercentages.forEach((item, totalPercentage) {
      // Round up to lowest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node requestItem edges for item $item percentage sum == $totalPercentage',
        );
      }
    });
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class ProdLineNodeStateBuilder
    implements NodeStateBuilder<ProdLineNodeStateImpl>, ProdLineNodeState {
  final ProdLineNode _node;

  bool _removingSelf = false;
  ItemIo? _requirements;
  ProductionLine _productionLine;
  ProductionLineIo? _io;
  NodeGeometryImpl _nodeGeometry;
  final Set<Edge> _parents;
  final Set<Edge> _children;

  @override
  ItemIo? get requirements => _requirements;
  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIo? get io => _io;
  @override
  NodeGeometryImpl get nodeGeometry => _nodeGeometry;
  @override
  late final Set<Edge> parents = UnmodifiableSetView(parents);
  @override
  late final Set<Edge> children = UnmodifiableSetView(children);

  ProdLineNodeStateBuilder._from(this._node)
    : _requirements = _node._state.requirements,
      _productionLine = _node._state.productionLine,
      _io = _node._state.io,
      _nodeGeometry = _node._state.nodeGeometry,
      _parents = Set.from(_node._state.parents),
      _children = Set.from(_node._state.children) {
    _node._basePlanner.getSnapshotBuilder().addToSnapsnot(_node, this);
  }

  @override
  void addSelf() {
    _node.parentGraph.getStateBuilder().addProdLineNode(_node);
  }

  @override
  void removeSelf() {
    if (!_removingSelf) {
      _removingSelf = true;
      _node._basePlanner.getSnapshotBuilder().removeFromSnapshot(_node);

      var edgesToRemove = [...parents, ...children];

      _parents.clear();
      _children.clear();

      for (var edge in edgesToRemove) {
        edge.getStateBuilder().removeSelf();
      }
    }
  }

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  void addParent(Edge parent) => _parents.add(parent);
  @override
  void addChild(Edge child) => _children.add(child);

  @override
  void removeParent(Edge parent) {
    if (!_removingSelf) {
      parent.getStateBuilder().removeSelf();
      _parents.remove(parent);
    }
  }

  @override
  void removeChild(Edge child) {
    if (!_removingSelf) {
      child.getStateBuilder().removeSelf();
      _children.remove(child);
    }
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

  void calculateIoFromEdgeConstraints() =>
      calculateIo(_calculateConstraintsFromEdges());

  ItemIo updateEdgesAndReturnUnfulfilledIo() {
    // TODO: optimise
    var ioData = _io;
    if (ioData == null) {
      for (var edge
          in _parents
              .where((parent) => parent.edgeType == EdgeType.pushExcess)
              .followedBy(
                _children.where(
                  (child) => child.edgeType == EdgeType.requestItems,
                ),
              )) {
        edge.getStateBuilder().clearAmount();
      }

      return ItemIo.empty;
    } else {
      var excessOutput = ItemAmounts.from(ioData.io.outputs);
      var requiredInput = ItemAmounts.from(ioData.io.inputs);

      var edgeConstraints = _calculateConstraintsFromEdges();

      excessOutput.updateAll(
        (item, amount) => amount - (edgeConstraints.outputs[item] ?? 0),
      );
      requiredInput.updateAll(
        (item, amount) => amount - (edgeConstraints.inputs[item] ?? 0),
      );

      ItemAmounts consumedOutput = {};
      ItemAmounts fulfilledInput = {};

      for (var pushExcessEdge in _parents.where(
        (edge) => edge.edgeType == EdgeType.pushExcess,
      )) {
        if (!excessOutput.containsKey(pushExcessEdge.item)) {
          throw NodeException(
            'Node $_node cannot produce item ${pushExcessEdge.item}',
          );
        }

        var edgeAmount =
            excessOutput[pushExcessEdge.item]! * pushExcessEdge.percentage;
        consumedOutput.update(
          pushExcessEdge.item,
          (amount) => amount + edgeAmount,
          ifAbsent: () => edgeAmount,
        );
        pushExcessEdge.getStateBuilder().updateAmount(edgeAmount);
      }

      for (var requestItemsEdge in _children.where(
        (edge) => edge.edgeType == EdgeType.requestItems,
      )) {
        if (!requiredInput.containsKey(requestItemsEdge.item)) {
          throw NodeException(
            'Node $_node cannot consume item ${requestItemsEdge.item}',
          );
        }

        var edgeAmount =
            excessOutput[requestItemsEdge.item]! * requestItemsEdge.percentage;
        fulfilledInput.update(
          requestItemsEdge.item,
          (amount) => amount + edgeAmount,
          ifAbsent: () => edgeAmount,
        );
        requestItemsEdge.getStateBuilder().updateAmount(edgeAmount);
      }

      excessOutput.updateAll(
        (item, amount) => amount - (consumedOutput[item] ?? 0),
      );
      requiredInput.updateAll(
        (item, amount) => amount - (fulfilledInput[item] ?? 0),
      );

      return ItemIo(inputs: requiredInput, outputs: excessOutput);
    }
  }

  ItemIo _calculateConstraintsFromEdges() {
    ItemAmounts outputConstraints = {};
    ItemAmounts inputConstraints = {};

    var outputConstraintParents = _parents.where(
      (parent) =>
          parent.edgeType == EdgeType.requestItems && parent.amount != null,
    );
    for (var parent in outputConstraintParents) {
      outputConstraints.update(
        parent.item,
        (itemConstraint) => itemConstraint + parent.amount!,
        ifAbsent: () => parent.amount!,
      );
    }

    var inputConstraintChildren = _parents.where(
      (parent) =>
          parent.edgeType == EdgeType.requestItems && parent.amount != null,
    );
    for (var child in inputConstraintChildren) {
      inputConstraints.update(
        child.item,
        (itemConstraint) => itemConstraint + child.amount!,
        ifAbsent: () => child.amount!,
      );
    }

    return ItemIo(inputs: inputConstraints, outputs: outputConstraints);
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl._(
    _node,
    requirements: _requirements,
    productionLine: _productionLine,
    io: _io,
    nodeGeometry: nodeGeometry,
    parents: _parents,
    children: _children,
  );
}
