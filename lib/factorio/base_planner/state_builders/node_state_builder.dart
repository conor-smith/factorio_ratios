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

  ProdLineNodeStateBuilder.initial(this._node, this._productionLine)
    : _internalConstraints = _node.nodeType.hasInternalConstraints
          ? ItemIoImpl.empty
          : null,
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
      _parents = Map.from(previousState.parents)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _children = Map.from(previousState.children)
        ..updateAll((item, edgeSet) => Set.from(edgeSet)),
      _ioData = previousState.ioData {
    _node.basePlanner.getSnapshotBuilder().addToSnapshot(_node, this);
  }

  @override
  void removeSelf() {
    _node.basePlanner.getSnapshotBuilder().removeFromSnapshot(_node);

    var edgesToRemove = parents.values
        .followedBy(children.values)
        .expand((edgeSet) => edgeSet)
        .toList();

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
    var removedOutputs = _productionLine.outputItems.difference(
      newLine.outputItems,
    );

    var edgesToRemove = removedInputs
        .map((output) => parents[output])
        .followedBy(removedOutputs.map((input) => children[input]))
        .nonNulls
        .expand((edgeSet) => edgeSet)
        .toList();

    for (var edgeToRemove in edgesToRemove) {
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

  @override
  void _parentGraphRemoval() {
    _node.basePlanner.getSnapshotBuilder().removeFromSnapshot(_node);

    _children.clear();
    _parents.clear();
  }

  @override
  void _addParent(Edge parent) => _parents.update(
    parent.item,
    (edges) => edges..add(parent),
    ifAbsent: () => {parent},
  );
  @override
  void _addChild(Edge child) => _children.update(
    child.item,
    (edges) => edges..add(child),
    ifAbsent: () => {child},
  );

  @override
  void _removeParent(Edge parent) => _parents[parent.item]?.remove(parent);
  @override
  void _removeChild(Edge child) => _children[child.item]?.remove(child);
}
