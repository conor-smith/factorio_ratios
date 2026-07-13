part of '../snapshot_builder.dart';

class ProdLineNodeStateBuilder extends NodeStateBuilder<ProdLineNodeStateImpl>
    with ProdLineNodeState {
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
    this._productionLine, [
    this._internalConstraints,
  ]) : _edgeConstraints = ItemIoImpl.empty,
       _unusedIo = ItemIoImpl.empty,
       _geometry = NodeGeometryImpl.uninitialised,
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
    _node.getSnapshotBuilderElement().queueIoUpdate();
  }

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

  @override
  void updateUnusedIo(ItemIoImpl newUnusedIo) {
    _unusedIo = newUnusedIo;
  }

  void updateIoData(ProductionLineIoData newIoData) {
    _ioData = newIoData;
  }

  void updateEdgeConstraints(ItemIoImpl newEdgeConstraints) {
    _edgeConstraints = newEdgeConstraints;
  }

  void updateProductionLine(ProductionLine newLine) {
    _node.getSnapshotBuilderElement().queueIoUpdate();

    var removedOutputs = _productionLine.outputItems.difference(
      newLine.outputItems,
    );
    var parentsToRemove = removedOutputs
        .map((removedOutput) => _parents[removedOutput])
        .nonNulls
        .expand((parentSet) => parentSet)
        .toList();

    for (var parent in parentsToRemove) {
      parent.getSnapshotBuilderElement()._removeSelfFromParentOnly();
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
      child.getSnapshotBuilderElement()._removeSelfFromChildOnly();
    }
    for (var input in removedInputs) {
      _children.remove(input);
    }

    if (_node.nodeType.outputPriority < 100) {
      _node.parentGraph.getSnapshotBuilderElement()._clearCachedOutputIndex();
    } else if (_node.nodeType == NodeType.disposal) {
      _node.parentGraph.getSnapshotBuilderElement()._clearCachedDisposalNodes();
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
    parents: parents..removeWhere((item, edges) => edges.isEmpty),
    children: children..removeWhere((item, edges) => edges.isEmpty),
  );
}
