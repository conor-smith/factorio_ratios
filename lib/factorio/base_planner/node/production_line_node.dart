part of 'node.dart';

class ProdLineNode extends NodeElement<ProdLineNodeStateImpl, NodeEvent> {
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
  ItemIoImpl get unusedIo => state.unusedIo;
  @override
  NodeGeometryImpl get geometry => state.geometry;
  @override
  Map<InGameItem, Set<Edge>> get parents => state.parents;
  @override
  Map<InGameItem, Set<Edge>> get children => state.children;
  @override
  Set<Edge> get allParents => state.allParents;
  @override
  Set<Edge> get allChildren => state.allChildren;

  ProductionLine get productionLine => state.productionLine;

  @override
  ItemIoImpl get ioRatios => state.ioRatios;
  @override
  ProductionLineType get productionLineType =>
      productionLine.productionLineType;
  @override
  Set<InGameItem> get inputItems => state.inputItems;
  @override
  Set<InGameItem> get outputItems => state.outputItems;

  @override
  ProductionLineIoData get ioData => state.ioData;

  ProdLineNodeStateImpl _internalState;

  ProdLineNode.addToBasePlanner(
    super.basePlanner, {
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
  }) : _internalState = ProdLineNodeStateImpl.uninitialised {
    basePlanner
        .getSnapshotBuilderOrThrow()
        .nodeBuilders[this] = SnapshotBuilderProdLineNode.newNode(
      this,
      _internalState,
      ProdLineNodeStateBuilder.initial(this, productionLine),
    );
  }

  ProdLineNodeState get state =>
      basePlanner.snapshotBuilder?.nodeBuilders[this]?.state ?? _internalState;

  @override
  void updateState(ProdLineNodeStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();
    _internalState = state;
  }

  @override
  SnapshotBuilderProdLineNode getSnapshotBuilderElement() =>
      basePlanner.getSnapshotBuilderOrThrow().nodeBuilders.putIfAbsent(
        this,
        () => SnapshotBuilderProdLineNode(this, _internalState),
      );

  @override
  ProdLineNodeStateBuilder getStateBuilder() =>
      getSnapshotBuilderElement().stateBuilder;

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
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  String toString() => productionLine.toString();
}

class NodeDependencies implements Dependencies {
  final Map<InGameItem, Set<Edge>> childDeps;
  final Map<InGameItem, Set<Edge>> parentDeps;

  NodeDependencies({required this.childDeps, required this.parentDeps});

  @override
  Iterable<Edge> get allElements => childDeps.values
      .followedBy(parentDeps.values)
      .expand((edgeSet) => edgeSet);
}
