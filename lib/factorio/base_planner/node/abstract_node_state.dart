part of 'node.dart';

abstract class AbstractNodeState {
  final ProductionLineIo? io;

  final NodeGeometryImpl nodeGeometry;

  final Set<Edge> parents;
  final Set<Edge> children;

  AbstractNodeState.initial({required this.io, required this.nodeGeometry})
    : parents = const {},
      children = const {};

  AbstractNodeState(
    NodeElement node, {
    required ProductionLine productionLine,
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
      // Round down to nearest 0.01
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
      // Rounded down to lowest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node requestItem edges for item $item percentage sum == $totalPercentage',
        );
      }
    });
  }
}

abstract class AbstractNodeStateBuilder<St> implements NodeStateBuilder<St> {
  NodeElement get node;

  bool _removingSelf = false;
  ProductionLineIo? _io;
  NodeGeometryImpl _nodeGeometry;
  final Set<Edge> _parents;
  final Set<Edge> _children;

  ProductionLineIo? get io => _io;
  NodeGeometryImpl get nodeGeometry => _nodeGeometry;
  late final Set<Edge> parents = UnmodifiableSetView(parents);
  late final Set<Edge> children = UnmodifiableSetView(children);

  AbstractNodeStateBuilder.from(NodeElement node)
    : _io = node.io,
      _nodeGeometry = node.nodeGeometry,
      _parents = Set.from(node.parents),
      _children = Set.from(node.children) {
    node.basePlanner.getSnapshotBuilder().addToSnapsnot(node, this);
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

  @override
  void removeSelf() {
    if (!_removingSelf) {
      _removingSelf = true;
      node.basePlanner.getSnapshotBuilder().removeFromSnapshot(node);

      var edgesToRemove = [...parents, ...children];

      _parents.clear();
      _children.clear();

      for (var edge in edgesToRemove) {
        edge.getStateBuilder().removeSelf();
      }
    }
  }

  void clearIo() {
    if (_io != null) {
      _io = null;
      clearParentIo();
    }
  }

  void calculateIo(ItemIo constraints) {
    _io = node.productionLine.calculate(constraints);
    clearParentIo();
  }

  void calculateIoFromEdgeConstraints() =>
      calculateIo(calculateConstraintsFromEdges());

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

      var edgeConstraints = calculateConstraintsFromEdges();

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
            'Node $node cannot produce item ${pushExcessEdge.item}',
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
            'Node $node cannot consume item ${requestItemsEdge.item}',
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

  ItemIo calculateConstraintsFromEdges() {
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

  void clearParentIo() {
    if (node.parentGraph.io != null) {
      node.parentGraph.getStateBuilder().clearIo();
    }
  }
}
