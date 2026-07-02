part of 'node.dart';

class ProdLineNode
    with EventNotifier<NodeEvent>
    implements NodeElement<ProdLineNodeState, NodeEvent> {
  @override
  final BasePlanner basePlanner;

  @override
  final Graph parentGraph;
  @override
  final NodeType nodeType;

  // For convenience
  @override
  ItemIoImpl? get internalConstraints => state.internalConstraints;
  @override
  ItemIo get edgeConstraints => state.edgeConstraints;
  @override
  ItemIo get itemIo => state.itemIo;
  ProductionLine get productionLine => state.productionLine;
  @override
  ProductionLineType get productionLineType =>
      productionLine.productionLineType;
  @override
  ItemIoImpl get ioRatios => productionLine.ioRatios;
  @override
  NodeGeometryImpl get geometry => state.geometry;
  @override
  Map<InGameItem, Set<Edge>> get parents => state.parents;
  @override
  Map<InGameItem, Set<Edge>> get children => state.children;
  @override
  ProductionLineIoData get ioData => state.ioData;
  @override
  Set<InGameItem> get inputItems => state.productionLine.inputItems;
  @override
  Set<InGameItem> get outputItems => state.productionLine.outputItems;

  ProdLineNodeStateImpl _state;
  ProdLineNodeStateBuilder? _builder;

  ProdLineNode.addToBasePlanner({
    required this.basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
  }) : _state = ProdLineNodeStateImpl.uninitialised {
    _builder = ProdLineNodeStateBuilder.initial(this, productionLine);
  }

  @override
  ProdLineNodeState get state => _builder ?? _state;
  @override
  set state(ProdLineNodeStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();
    _builder = null;
    _state = state;
  }

  @override
  ProdLineNodeStateBuilder getStateBuilder() {
    _builder ??= ProdLineNodeStateBuilder.from(this, _state);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => basePlanner.selectedElements.contains(this);

  @override
  void select() => basePlanner.selectElement(this);

  @override
  void deselect() => basePlanner.deselectElement(this);

  @override
  ProdLineNode getOutputItemNode(InGameItem item) {
    if (outputItems.contains(item)) {
      return this;
    } else {
      throw NodeException('Node $this cannot produce $item');
    }
  }

  @override
  ProdLineNode getInputItemNode(InGameItem item) {
    if (inputItems.contains(item)) {
      return this;
    } else {
      throw NodeException('Node $this cannot consume $item');
    }
  }

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometryImpl geometry) =>
      notifyListeners(NodeEvent.geometryOp(geometry));

  @override
  void notifyListenersOfStateUpdate(
    ProdLineNodeStateImpl oldState,
    ProdLineNodeStateImpl newState,
  ) {
    if (oldState.geometry != newState.geometry) {
      notifyListeners(NodeEvent.geometryOp(newState.geometry));
    }
  }

  @override
  Iterable<Edge> getIoDependencies() => [
    ...parents.values
        .expand((edgeSet) => edgeSet)
        .where((edge) => edge.edgeType == EdgeType.requestItems),
    ...children.values
        .expand((edgeSet) => edgeSet)
        .where((edge) => edge.edgeType == EdgeType.pushExcess),
  ];

  @override
  bool traverseDependenciesAndUpdateIo(
    Set<BasePlannerElement> visitedElements,
  ) {
    throw UnimplementedError();
  }

  ItemIoImpl determineEdgeConstraints() {
    var edgeConstraints = ItemIoBuilder();

    parents.forEach((item, edges) {
      var itemRequestSum = edges
          .where((edge) => edge.edgeType == EdgeType.requestItems)
          .fold(0.0, (sum, edge) => sum + edge.amount);
      edgeConstraints.addToOutputs(item, itemRequestSum);
    });

    children.forEach((item, edges) {
      var pushExcessSum = edges
          .where((edge) => edge.edgeType == EdgeType.requestExcess)
          .fold(0.0, (sum, edge) => sum + edge.amount);
      edgeConstraints.addToInputs(item, pushExcessSum);
    });

    return edgeConstraints.build();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  String toString() => productionLine.toString();
}
