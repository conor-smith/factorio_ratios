part of 'state_builders.dart';

abstract class AbstractNodeStateBuilder<St> implements NodeStateBuilder<St> {
  NodeElement get node;
  ProductionLine get productionLine;
  ProductionLineIo get io;
  void calculateIo(ItemIo constraints);

  bool _removingSelf = false;
  NodeGeometryImpl _geometry;
  final Set<Edge> _parents;
  final Set<Edge> _children;

  NodeGeometryImpl get geometry => _geometry;
  late final Set<Edge> parents = UnmodifiableSetView(_parents);
  late final Set<Edge> children = UnmodifiableSetView(_children);

  AbstractNodeStateBuilder.from(NodeElement node, NodeState previousState)
    : _geometry = previousState.geometry,
      _parents = Set.from(previousState.parents),
      _children = Set.from(previousState.children);

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

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
    if (io.io.isEmpty) {
      for (var edge
          in _parents
              .where((parent) => parent.edgeType == EdgeType.pushExcess)
              .followedBy(
                _children.where(
                  (child) => child.edgeType == EdgeType.requestItems,
                ),
              )) {
        edge.getStateBuilder().updateAmount(0);
      }

      return ItemIo.empty;
    } else {
      var excessOutput = ItemAmounts.from(io.io.outputs);
      var requiredInput = ItemAmounts.from(io.io.inputs);

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
    ItemAmounts outputConstraints = Map.fromIterable(
      productionLine.outputItems,
      value: (item) => 0,
    );
    ItemAmounts inputConstraints = Map.fromIterable(
      productionLine.inputItems,
      value: (item) => 0,
    );

    var outputConstraintParents = _parents.where(
      (parent) => parent.edgeType == EdgeType.requestItems,
    );
    for (var parent in outputConstraintParents) {
      outputConstraints.update(
        parent.item,
        (itemConstraint) => itemConstraint + parent.amount,
      );
    }

    var inputConstraintChildren = _parents.where(
      (parent) => parent.edgeType == EdgeType.requestItems,
    );
    for (var child in inputConstraintChildren) {
      inputConstraints.update(
        child.item,
        (itemConstraint) => itemConstraint + child.amount,
      );
    }

    return ItemIo(inputs: inputConstraints, outputs: outputConstraints);
  }

  void updateParentIo() {
    node.basePlanner.getSnapshotBuilder().queueGraphIoUpdate(node.parentGraph);
  }
}
