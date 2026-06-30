part of 'state_builders.dart';

class ProdLineNodeStateBuilder extends StateBuilder<ProdLineNodeStateImpl>
    implements ProdLineNodeState {
  @override
  final ProdLineNode _element;

  ItemIoImpl? _internalConstraints;
  ItemIoBuilder _edgeConstraints;
  ItemIoImpl _itemIo;
  NodeGeometryImpl _geometry;
  ProductionLine _productionLine;
  ProductionLineIoData _ioData;
  final Map<InGameItem, Set<Edge>> _parents;
  final Map<InGameItem, Set<Edge>> _children;

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
      _edgeConstraints = ItemIoBuilder(),
      _itemIo = ItemIoImpl.empty,
      _geometry = NodeGeometryImpl.uninitialised,
      _ioData = ProductionLineIoData.uninitialised,
      _parents = {},
      _children = {} {
    var parentGraph = _element.parentGraph;
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

    parentGraph.getStateBuilder()._addNodeToCaches(_element);
  }

  ProdLineNodeStateBuilder.from(
    this._element,
    ProdLineNodeStateImpl previousState,
  ) : _internalConstraints = previousState.internalConstraints,
      _edgeConstraints = ItemIoBuilder.from(previousState.edgeConstraints),
      _itemIo = previousState.itemIo,
      _productionLine = previousState.productionLine,
      _geometry = previousState.geometry,
      _parents = Map.from(previousState.parents)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _children = Map.from(previousState.children)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _ioData = previousState.ioData {
    if (_element.parentGraph.hasBuilder) {
      _element.parentGraph.getStateBuilder()._addNodeToCaches(_element);
    }
  }

  @override
  void removeSelf() {
    _snapshotBuilder.removeFromSnapshot(_element);
    for (var parent in _parents.values.expand((edgeSet) => edgeSet)) {
      _removeParentFromDownstreamElements(parent);
    }

    for (var child in _children.values.expand((edgeSet) => edgeSet)) {
      _removeChildFromDownstreamElements(child);
    }

    _parents.clear();
    _children.clear();

    var parentGraph = _element.parentGraph;
    switch (_element.nodeType) {
      case NodeType.input:
        parentGraph.getStateBuilder()._inputNodes.remove(
          _productionLine.inputItems.first,
        );

      case NodeType.output:
        parentGraph.getStateBuilder()._outputNodes.remove(
          _productionLine.outputItems.first,
        );

      default:
        parentGraph.getStateBuilder()._prodLineNodes.remove(_element);
    }

    parentGraph.getStateBuilder()._removeNodeFromCaches(_element);
  }

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

  void updateInternalConstraints(ItemIoImpl newConstraints) {
    _internalConstraints = newConstraints;
  }

  void updateProductionLine(ProductionLine newLine) {
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

    if (_element.parentGraph.hasBuilder) {
      if (_element.nodeType.outputPriority < 100) {
        _element.parentGraph.getStateBuilder()._clearCachedOutputIndex();
      } else if (_element.nodeType == NodeType.disposal) {
        _element.parentGraph.getStateBuilder()._clearCachedDisposalNodes();
      }
    }
  }

  @override
  void performIoUpdate() {
    // TODO
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl(
    _element,
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
    _snapshotBuilder.removeFromSnapshot(parent);

    parent.parentProdLine.getStateBuilder()._children[parent.item]!.remove(
      parent,
    );

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.children, which is determined dynamically, is updated
    parent.parent.getStateBuilder();
  }

  void _removeChildFromDownstreamElements(Edge child) {
    _snapshotBuilder.removeFromSnapshot(child);

    child.childProdLine.getStateBuilder()._parents[child.item]!.remove(child);

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents, which is determined dynamically, is updated
    child.child.getStateBuilder();
  }

  // Used by parentGraph when doing bulk removals
  void _removeSelfButNotOthers() {
    _snapshotBuilder.removeFromSnapshot(_element);

    _parents.clear();
    _children.clear();
  }
}
