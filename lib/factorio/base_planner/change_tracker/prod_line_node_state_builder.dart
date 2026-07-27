part of 'change_trackers.dart';

class ProdLineNodeStateBuilder extends ProdLineNodeState
    implements NodeStateBuilder<ProdLineNodeStateImpl> {
  final ProdLineNode _node;

  ItemIoImpl? _internalConstraints;
  ItemIoImpl _edgeConstraints;
  ItemIoImpl _unusedIo;
  NodeGeometryImpl _geometry;
  ProductionLine _productionLine;
  ProductionLineIoData _ioData;
  final Map<InGameItem, Set<Edge>> _parents;
  final Map<InGameItem, Set<Edge>> _children;

  @override
  ItemIoImpl? get internalConstraints => _internalConstraints;
  @override
  ItemIoImpl get edgeConstraints => _edgeConstraints;
  @override
  ItemIoImpl get unusedIo => _unusedIo;
  @override
  NodeGeometryImpl get geometry => _geometry;
  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIoData get ioData => _ioData;

  // Do not modify the values of these maps directly
  @override
  late final Map<InGameItem, Set<Edge>> parents = UnmodifiableMapView(_parents);
  @override
  late final Map<InGameItem, Set<Edge>> children = UnmodifiableMapView(
    _children,
  );

  ProdLineNodeStateBuilder.initial(
    this._node,
    this._productionLine,
    this._internalConstraints,
    this._geometry,
  ) : _edgeConstraints = ItemIoImpl.empty,
      _unusedIo = ItemIoImpl.empty,
      _ioData = ProductionLineIoData.uninitialised,
      _parents = {},
      _children = {};

  ProdLineNodeStateBuilder.from(this._node, ProdLineNodeStateImpl previousState)
    : _internalConstraints = previousState.internalConstraints,
      _edgeConstraints = previousState.edgeConstraints,
      _unusedIo = previousState.unusedIo,
      _productionLine = previousState.productionLine,
      _geometry = previousState.geometry,
      _parents = Map.from(previousState.parents)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _children = Map.from(previousState.children)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _ioData = previousState.ioData;

  void updateInternalConstraints(ItemIoImpl newConstraints) {
    _internalConstraints = newConstraints;
    _node.getChangeTracker().queueIoUpdate();
  }

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

  void updateProductionLine(ProductionLine newLine) {
    _node.getChangeTracker().queueIoUpdate();

    var removedOutputs = _productionLine.outputItems.difference(
      newLine.outputItems,
    );
    var parentsToRemove = removedOutputs
        .map((removedOutput) => _parents[removedOutput])
        .nonNulls
        .expand((parentSet) => parentSet)
        .toList();

    for (var parent in parentsToRemove) {
      parent.getChangeTracker()._removeSelfFromParentOnly();
    }
    for (var output in removedOutputs) {
      _parents.remove(output);
    }

    var removedInputs = _productionLine.inputItems.difference(
      newLine.inputItems,
    );
    var childrenToRemove = removedInputs
        .map((removedInput) => _children[removedInput])
        .nonNulls
        .expand((childSet) => childSet)
        .toList();

    for (var child in childrenToRemove) {
      child.getChangeTracker()._removeSelfFromChildOnly();
    }
    for (var input in removedInputs) {
      _children.remove(input);
    }

    if (_node.nodeType.outputPriority < 100) {
      _node.parentGraph.getChangeTracker()._clearCachedOutputIndex();
    } else if (_node.nodeType == NodeType.disposal) {
      _node.parentGraph.getChangeTracker()._clearCachedDisposalNodes();
    }

    _productionLine = newLine;
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl(
    _node,
    internalConstraints: _internalConstraints,
    edgeConstraints: _edgeConstraints,
    unusedIo: _unusedIo,
    productionLine: productionLine,
    ioData: _ioData,
    geometry: _geometry,
    parents: _parents..removeWhere((item, edges) => edges.isEmpty),
    children: _children..removeWhere((item, edges) => edges.isEmpty),
  );

  @override
  void _updateUnusedIo(ItemIoImpl newUnusedIo) {
    _unusedIo = newUnusedIo;
  }

  void _updateIoData(ProductionLineIoData newIoData) {
    _ioData = newIoData;
  }

  void _updateEdgeConstraints(ItemIoImpl newEdgeConstraints) {
    _edgeConstraints = newEdgeConstraints;
  }
}
