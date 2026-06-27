part of 'state_builders.dart';

class ProdLineNodeStateBuilder
    implements NodeStateBuilder<ProdLineNodeStateImpl>, ProdLineNodeState {
  final ProdLineNode _node;

  ItemIoImpl? _internalConstraints;
  ItemIoBuilder _edgeConstraints;
  ItemIoImpl _itemIo;
  NodeGeometryImpl _geometry;
  ProductionLine _productionLine;
  ProductionLineIoData _ioData;
  final Set<Edge> _parents;
  final Set<Edge> _children;

  @override
  ItemIo? get internalConstraints => _internalConstraints;
  @override
  ItemIo get edgeConstraints => _edgeConstraints;
  @override
  ItemIo get itemIo => _itemIo;
  @override
  NodeGeometryImpl get geometry => _geometry;
  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIoData get ioData => _ioData;
  @override
  late final Set<Edge> parents = UnmodifiableSetView(_parents);
  @override
  late final Set<Edge> children = UnmodifiableSetView(_children);

  ProdLineNodeStateBuilder.initial(this._node, this._productionLine)
    : _internalConstraints = _node.nodeType.isRoot ? ItemIoImpl.empty : null,
      _edgeConstraints = ItemIoBuilder(),
      _itemIo = ItemIoImpl.empty,
      _geometry = NodeGeometryImpl.uninitialised,
      _ioData = ProductionLineIoData.uninitialised,
      _parents = {},
      _children = {} {
    _node.basePlanner.getSnapshotBuilder().addToSnapshot(_node, this);

    switch (_node.nodeType) {
      case NodeType.input:
        _node.parentGraph.getStateBuilder()._addInputNode(
          _node,
          _productionLine.inputItems.first,
        );

      case NodeType.output:
        _node.parentGraph.getStateBuilder()._addOutputNode(
          _node,
          _productionLine.outputItems.first,
        );

      default:
        _node.parentGraph.getStateBuilder()._addProdLineNode(_node);
    }
  }

  ProdLineNodeStateBuilder.from(this._node, ProdLineNodeStateImpl previousState)
    : _internalConstraints = previousState.internalConstraints,
      _edgeConstraints = ItemIoBuilder.from(previousState.edgeConstraints),
      _itemIo = previousState.itemIo,
      _productionLine = previousState.productionLine,
      _geometry = previousState.geometry,
      _parents = Set.from(previousState.parents),
      _children = Set.from(previousState.children),
      _ioData = previousState.ioData {
    _node.basePlanner.getSnapshotBuilder().addToSnapshot(_node, this);
  }

  @override
  void removeSelf() {
    _node.basePlanner.getSnapshotBuilder().removeFromSnapshot(_node);

    var edgesToRemove = [...parents, ...children];

    _parents.clear();
    _children.clear();

    for (var edge in edgesToRemove) {
      edge.getStateBuilder().removeSelf();
    }

    switch (_node.nodeType) {
      case NodeType.input:
        _node.parentGraph.getStateBuilder()._removeInputNode(
          (_productionLine as IoLine).ioItem,
        );

      case NodeType.output:
        _node.parentGraph.getStateBuilder()._removeOutputNode(
          (_productionLine as IoLine).ioItem,
        );

      default:
        _node.parentGraph.getStateBuilder()._removeProdLineNode(_node);
    }
  }

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

  void updateRequirements(ItemIoImpl newRequirements) =>
      _internalConstraints = newRequirements;

  void updateProductionLine(ProductionLine newLine) {
    var removedInputs = _productionLine.inputItems.difference(
      newLine.inputItems,
    );
    var childrenToRemove = _children.where(
      (child) => removedInputs.contains(child.item),
    );

    var removedOutputs = _productionLine.outputItems.difference(
      newLine.outputItems,
    );
    var parentsToRemove = _parents.where(
      (parent) => removedOutputs.contains(parent.item),
    );

    for (var edgeToRemove in [...childrenToRemove, ...parentsToRemove]) {
      edgeToRemove.getStateBuilder().removeSelf();
    }

    _productionLine = newLine;

    if (_node.parentGraph.hasBuilder) {
      if (_node.nodeType.outputPriority < 100) {
        _node.parentGraph.getStateBuilder()._clearCachedOutputIndex();
      } else if (_node.nodeType == NodeType.disposal) {
        _node.parentGraph.getStateBuilder()._clearCachedDisposalNodes();
      }
    }
  }

  void calculateIo(ItemIoImpl constraints) =>
      _ioData = productionLine.calculateIoData(constraints);

  ItemIoImpl calculateConstraintsFromEdges() {
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

    return ItemIoImpl(inputs: inputConstraints, outputs: outputConstraints);
  }

  ItemIoImpl updateEdgesAndReturnUnfulfilledIo() {
    // TODO: optimise
    if (ioData.io.isEmpty) {
      for (var edge
          in _parents
              .where((parent) => parent.edgeType == EdgeType.pushExcess)
              .followedBy(
                _children.where(
                  (child) => child.edgeType == EdgeType.requestItems,
                ),
              )) {
        edge.getStateBuilder()._updateAmount(0);
      }

      return ItemIoImpl.empty;
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
        pushExcessEdge.getStateBuilder()._updateAmount(edgeAmount);
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
        requestItemsEdge.getStateBuilder()._updateAmount(edgeAmount);
      }

      excessOutput.updateAll(
        (item, amount) => amount - (consumedOutput[item] ?? 0),
      );
      requiredInput.updateAll(
        (item, amount) => amount - (fulfilledInput[item] ?? 0),
      );

      return ItemIoImpl(inputs: requiredInput, outputs: excessOutput);
    }
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl(
    _node,
    internalConstraints: _internalConstraints,
    edgeConstraints: _edgeConstraints.build(),
    itemIo: _itemIo,
    productionLine: productionLine,
    ioData: ioData,
    geometry: geometry,
    parents: parents,
    children: children,
  );

  @override
  void _parentGraphRemoval() {
    _node.basePlanner.getSnapshotBuilder().removeFromSnapshot(_node);

    _children.clear();
    _parents.clear();
  }

  @override
  void _addParent(Edge parent) => _parents.add(parent);
  @override
  void _addChild(Edge child) => _children.add(child);

  @override
  void _removeParent(Edge parent) => _parents.remove(parent);
  @override
  void _removeChild(Edge child) => _children.remove(child);
}
