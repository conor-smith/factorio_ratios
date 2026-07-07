part of 'state_builders.dart';

class ProdLineNodeStateBuilder extends StateBuilder<ProdLineNodeStateImpl>
    implements ProdLineNodeState {
  @override
  final ProdLineNode _element;

  ItemIoImpl? _internalConstraints;
  ItemIoImpl _edgeConstraints;
  ItemIoImpl _itemIo;
  NodeGeometryImpl _geometry;
  ProductionLine _productionLine;
  ProductionLineIoData _ioData;
  final Map<InGameItem, Set<Edge>> _parents;
  final Map<InGameItem, Set<Edge>> _children;

  @override
  ItemIoImpl? get internalConstraints => _internalConstraints;
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

  // Do not modify the values of these maps directly
  @override
  late final Map<InGameItem, Set<Edge>> parents = UnmodifiableMapView(_parents);
  @override
  late final Map<InGameItem, Set<Edge>> children = UnmodifiableMapView(
    _children,
  );

  ProdLineNodeStateBuilder.initial(this._element, this._productionLine)
    : _internalConstraints = _element.nodeType.hasInternalConstraints
          ? ItemIoImpl.empty
          : null,
      _edgeConstraints = ItemIoImpl.empty,
      _itemIo = ItemIoImpl.empty,
      _geometry = NodeGeometryImpl.uninitialised,
      _ioData = ProductionLineIoData.uninitialised,
      _parents = {},
      _children = {},
      super.initial() {
    var parentGraph = _element.parentGraph;

    _snapshotBuilder.queueLayoutUpdate(parentGraph);

    switch (_element.nodeType) {
      case NodeType.input:
        var inputItem = productionLine.inputItems.first;
        if (parentGraph.inputNodes.containsKey(inputItem)) {
          throw GraphException(
            'Input node for item $inputItem in graph $parentGraph already exists',
          );
        } else {
          parentGraph.getStateBuilder()._inputNodes[inputItem] = _element;
        }

      case NodeType.output:
        var outputItem = productionLine.outputItems.first;
        if (parentGraph.outputNodes.containsKey(outputItem)) {
          throw GraphException(
            'Output node for item $outputItem in graph $parentGraph already exists',
          );
        } else {
          parentGraph.getStateBuilder()._outputNodes[outputItem] = _element;
        }

        // Clear cached output index of "grandparent graph" if required
        if (parentGraph.parentGraph.hasBuilder) {
          parentGraph.parentGraph.getStateBuilder()._clearCachedOutputIndex();
        }

      default:
        _element.parentGraph.getStateBuilder()._prodLineNodes.add(_element);
    }

    parentGraph.getStateBuilder()._addNodeToNodeCaches(_element);
  }

  ProdLineNodeStateBuilder.from(
    this._element,
    ProdLineNodeStateImpl previousState,
  ) : _internalConstraints = previousState.internalConstraints,
      _edgeConstraints = previousState.edgeConstraints,
      _itemIo = previousState.itemIo,
      _productionLine = previousState.productionLine,
      _geometry = previousState.geometry,
      _parents = Map.from(previousState.parents)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _children = Map.from(previousState.children)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _ioData = previousState.ioData,
      super.from() {
    if (_element.parentGraph.hasBuilder) {
      _element.parentGraph.getStateBuilder()._addNodeToNodeCaches(_element);
    }
  }

  @override
  void removeSelf() {
    var parentGraph = _element.parentGraph;

    _snapshotBuilder
      ..queueRequiredIoUpdate(parentGraph)
      ..queueLayoutUpdate(parentGraph)
      ..removeFromSnapshot(_element);
    for (var parent in _parents.values.expand((edgeSet) => edgeSet)) {
      parent.getStateBuilder()._removeSelfAndUpdateParentOnly();
    }

    for (var child in _children.values.expand((edgeSet) => edgeSet)) {
      child.getStateBuilder()._removeSelfAndUpdateChildOnly();
    }

    _parents.clear();
    _children.clear();

    switch (_element.nodeType) {
      case NodeType.input:
        parentGraph.getStateBuilder()._inputNodes.remove(
          _productionLine.inputItems.first,
        );

      case NodeType.output:
        parentGraph.getStateBuilder()._outputNodes.remove(
          _productionLine.outputItems.first,
        );
        if (parentGraph.parentGraph.hasBuilder) {
          parentGraph.parentGraph.getStateBuilder()._clearCachedOutputIndex();
        }

      default:
        parentGraph.getStateBuilder()._prodLineNodes.remove(_element);
    }

    parentGraph.getStateBuilder()._removeNodeFromNodeCaches(_element);
  }

  @override
  void updateGeometry(NodeGeometryImpl geometry) {
    // TODO - Centralise this code rather than copying it
    if (_snapshotBuilder.stage != SnapshotBuildStage.updateGraphLayouts &&
        _element.parentGraph.layout != GraphLayout.custom) {
      _element.parentGraph.getStateBuilder()._layout = GraphLayout.custom;
    }

    _geometry = geometry;
  }

  void updateInternalConstraints(ItemIoImpl newConstraints) {
    _snapshotBuilder.queueRequiredIoUpdate(_element);
    _internalConstraints = newConstraints;
  }

  void updateIo(ItemIoImpl newItemIo) {
    _snapshotBuilder.throwIfNotBuildingIo();

    _itemIo = newItemIo;
  }

  void updateEdgeConstraints(ItemIoImpl newEdgeConstraints) {
    _snapshotBuilder.throwIfNotBuildingIo();

    _edgeConstraints = newEdgeConstraints;
  }

  void updateProductionLine(ProductionLine newLine) {
    _snapshotBuilder.queueRequiredIoUpdate(_element);

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
      parent.getStateBuilder()._removeSelfAndUpdateParentOnly();
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
      child.getStateBuilder()._removeSelfAndUpdateChildOnly();
    }

    if (_element.parentGraph.hasBuilder) {
      if (_element.nodeType.outputPriority < 100) {
        _element.parentGraph.getStateBuilder()._clearCachedOutputIndex();
      } else if (_element.nodeType == NodeType.disposal) {
        _element.parentGraph.getStateBuilder()._clearCachedDisposalNodes();
      }
    }

    _productionLine = newLine;
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl(
    _element,
    internalConstraints: _internalConstraints,
    edgeConstraints: _edgeConstraints,
    itemIo: _itemIo,
    productionLine: productionLine,
    ioData: ioData,
    geometry: geometry,
    parents: parents..removeWhere((item, edges) => edges.isEmpty),
    children: children..removeWhere((item, edges) => edges.isEmpty),
  );

  // Used by parentGraph when doing bulk removals
  void _removeSelfButNotOthers() {
    _snapshotBuilder.removeFromSnapshot(_element);

    _parents.clear();
    _children.clear();
  }
}
