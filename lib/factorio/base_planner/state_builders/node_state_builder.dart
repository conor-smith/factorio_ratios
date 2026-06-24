part of 'state_builders.dart';

abstract class AbstractNodeStateBuilder<St> implements NodeStateBuilder<St> {
  NodeElement get node;
  ProductionLine get productionLine;
  ProductionLineIo? get io;
  void calculateIo(ItemIo constraints);
  void clearIo();

  bool _removingSelf = false;
  NodeGeometryImpl _nodeGeometry;
  final Set<Edge> _parents;
  final Set<Edge> _children;

  NodeGeometryImpl get nodeGeometry => _nodeGeometry;
  late final Set<Edge> parents = UnmodifiableSetView(parents);
  late final Set<Edge> children = UnmodifiableSetView(children);

  AbstractNodeStateBuilder.from(NodeElement node, NodeState previousState)
    : _nodeGeometry = previousState.nodeGeometry,
      _parents = Set.from(previousState.parents),
      _children = Set.from(previousState.children);

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

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

  @override
  void _addParent(Edge parent) => _parents.add(parent);
  @override
  void _addChild(Edge child) => _children.add(child);

  @override
  void _removeParent(Edge parent) {
    if (!_removingSelf) {
      parent.getStateBuilder().removeSelf();
      _parents.remove(parent);
    }
  }

  @override
  void _removeChild(Edge child) {
    if (!_removingSelf) {
      child.getStateBuilder().removeSelf();
      _children.remove(child);
    }
  }

  void calculateIoFromEdgeConstraints() =>
      calculateIo(calculateConstraintsFromEdges());

  ItemIo updateEdgesAndReturnUnfulfilledIo() {
    // TODO: optimise
    var ioData = io;
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
