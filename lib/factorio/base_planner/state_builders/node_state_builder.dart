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
  final Map<InGameItem, Set<Edge>> _parents;
  final Map<InGameItem, Set<Edge>> _children;

  IoUpdateStatus _ioUpdateStatus;

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
  IoUpdateStatus get ioUpdateStatus => _ioUpdateStatus;

  // Do not modify the values of these maps directly
  @override
  late final Map<InGameItem, Set<Edge>> parents = UnmodifiableMapView(_parents);
  @override
  late final Map<InGameItem, Set<Edge>> children = UnmodifiableMapView(
    _children,
  );

  ProdLineNodeStateBuilder.initial(this._node, this._productionLine)
    : _internalConstraints = _node.nodeType.hasInternalConstraints
          ? ItemIoImpl.empty
          : null,
      _edgeConstraints = ItemIoBuilder(),
      _itemIo = ItemIoImpl.empty,
      _geometry = NodeGeometryImpl.uninitialised,
      _ioData = ProductionLineIoData.uninitialised,
      _parents = {},
      _children = {},
      _ioUpdateStatus = IoUpdateStatus.pending {
    _node.basePlanner.getSnapshotBuilder()
      ..addToSnapshot(_node, this)
      ..queueIoUpdate(_node);

    var parentGraph = _node.parentGraph;
    switch (_node.nodeType) {
      case NodeType.input:
        var inputItem = productionLine.inputItems.first;
        if (parentGraph.inputNodes.containsKey(inputItem)) {
          throw GraphException(
            'Input node for item $inputItem in graph $parentGraph already exists',
          );
        } else {
          parentGraph.getStateBuilder()._inputNodes[inputItem] = _node;
        }

      case NodeType.output:
        var outputItem = productionLine.outputItems.first;
        if (parentGraph.outputNodes.containsKey(outputItem)) {
          throw GraphException(
            'Output node for item $outputItem in graph $parentGraph already exists',
          );
        } else {
          parentGraph.getStateBuilder()._outputNodes[outputItem] = _node;
        }

        // Clear cached output index of "grandparent graph" if required
        if (parentGraph.parentGraph.hasBuilder) {
          parentGraph.parentGraph.getStateBuilder()._clearCachedOutputIndex();
        }

      default:
        _node.parentGraph.getStateBuilder()._prodLineNodes.add(_node);
    }

    parentGraph.getStateBuilder()._addNodeToCaches(_node);
  }

  ProdLineNodeStateBuilder.from(this._node, ProdLineNodeStateImpl previousState)
    : _internalConstraints = previousState.internalConstraints,
      _edgeConstraints = ItemIoBuilder.from(previousState.edgeConstraints),
      _itemIo = previousState.itemIo,
      _productionLine = previousState.productionLine,
      _geometry = previousState.geometry,
      _parents = Map.from(previousState.parents)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _children = Map.from(previousState.children)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _ioData = previousState.ioData,
      _ioUpdateStatus = IoUpdateStatus.notRequired {
    _node.basePlanner.getSnapshotBuilder().addToSnapshot(_node, this);

    if (_node.parentGraph.hasBuilder) {
      _node.parentGraph.getStateBuilder()._addNodeToCaches(_node);
    }
  }

  void _queueIoUpdate() {
    if (_ioUpdateStatus != IoUpdateStatus.notRequired) {
      _ioUpdateStatus = IoUpdateStatus.pending;
      _node.basePlanner.getSnapshotBuilder().queueIoUpdate(_node);
    }
  }

  @override
  void performIoUpdate(Set<BasePlannerElement> visitedElements) {
    // TODO: implement performIoUpdate
  }

  @override
  void removeSelf() {
    var snapshotBuilder = _node.basePlanner.getSnapshotBuilder();

    snapshotBuilder.removeFromSnapshot(_node);
    for (var parent in _parents.values.expand((edgeSet) => edgeSet)) {
      _removeParentFromDownstreamElements(parent);
    }

    for (var child in _children.values.expand((edgeSet) => edgeSet)) {
      _removeChildFromDownstreamElements(child);
    }

    _parents.clear();
    _children.clear();

    var parentGraph = _node.parentGraph;
    switch (_node.nodeType) {
      case NodeType.input:
        parentGraph.getStateBuilder()._inputNodes.remove(
          _productionLine.inputItems.first,
        );

      case NodeType.output:
        parentGraph.getStateBuilder()._outputNodes.remove(
          _productionLine.outputItems.first,
        );

      default:
        parentGraph.getStateBuilder()._prodLineNodes.remove(_node);
    }

    parentGraph.getStateBuilder()._removeNodeFromCaches(_node);
  }

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

  void updateInternalConstraints(ItemIoImpl newConstraints) {
    if (_internalConstraints != newConstraints) {
      _internalConstraints = newConstraints;
      _queueIoUpdate();
    }
  }

  void updateProductionLine(ProductionLine newLine) {
    _queueIoUpdate();

    var removedOutputs = _productionLine.outputItems.difference(
      newLine.outputItems,
    );
    var parentsToRemove = removedOutputs
        .map((removedOutput) => _parents[removedOutput])
        .nonNulls
        .expand((parentSet) => parentSet)
        .toList();

    for (var output in removedOutputs) {
      _parents.remove(output);
    }
    for (var parent in parentsToRemove) {
      _removeParentFromDownstreamElements(parent);
    }

    var removedInputs = _productionLine.inputItems.difference(
      newLine.inputItems,
    );
    var childrenToRemove = removedInputs
        .map((removedInput) => _children[removedInput])
        .nonNulls
        .expand((childSet) => childSet)
        .toList();

    for (var input in removedInputs) {
      _children.remove(input);
    }
    for (var child in childrenToRemove) {
      _removeChildFromDownstreamElements(child);
    }

    if (_node.parentGraph.hasBuilder) {
      if (_node.nodeType.outputPriority < 100) {
        _node.parentGraph.getStateBuilder()._clearCachedOutputIndex();
      } else if (_node.nodeType == NodeType.disposal) {
        _node.parentGraph.getStateBuilder()._clearCachedDisposalNodes();
      }
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
    parents: parents..removeWhere((item, edges) => edges.isEmpty),
    children: children..removeWhere((item, edges) => edges.isEmpty),
  );

  void _removeParentFromDownstreamElements(Edge parent) {
    _node.basePlanner.getSnapshotBuilder().removeFromSnapshot(parent);

    parent.parentProdLine.getStateBuilder()._children[parent.item]!.remove(
      parent,
    );

    parent.getStateBuilder()._queueParentsAffectedByRemoval();

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.children, which is determined dynamically, is updated
    parent.parent.getStateBuilder();
  }

  void _removeChildFromDownstreamElements(Edge child) {
    _node.basePlanner.getSnapshotBuilder().removeFromSnapshot(child);

    child.childProdLine.getStateBuilder()._parents[child.item]!.remove(child);

    child.getStateBuilder()._queueChildrenAffectedByRemoval();

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents, which is determined dynamically, is updated
    child.child.getStateBuilder();
  }
}
