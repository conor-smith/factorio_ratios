part of 'node.dart';

class ProdLineNode
    extends NodeElement<ProdLineNodeStateImpl, ProdLineNodeEvent> {
  @override
  final Graph parentGraph;
  @override
  final NodeType nodeType;

  // For convenience
  @override
  ItemIoImpl? get internalConstraints => _state.internalConstraints;
  @override
  ItemIo get edgeConstraints => _state.edgeConstraints;
  @override
  ItemIoImpl get unusedIo => _state.unusedIo;
  @override
  NodeGeometryImpl get geometry => _state.geometry;
  @override
  Map<InGameItem, Set<Edge>> get parents => _state.parents;
  @override
  Map<InGameItem, Set<Edge>> get children => _state.children;
  @override
  Set<Edge> get allParents => _state.allParents;
  @override
  Set<Edge> get allChildren => _state.allChildren;

  ProductionLine get productionLine => _state.productionLine;

  @override
  ItemIoImpl get ioRatios => _state.ioRatios;
  @override
  ProductionLineType get productionLineType =>
      productionLine.productionLineType;
  @override
  Set<InGameItem> get inputItems => _state.inputItems;
  @override
  Set<InGameItem> get outputItems => _state.outputItems;

  @override
  ProductionLineIoData get ioData => _state.ioData;

  ProdLineNodeStateImpl _internalState;

  ProdLineNode.addToBasePlanner(
    super.basePlanner, {
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
    ItemIoImpl? internalConstraints,
  }) : _internalState = ProdLineNodeStateImpl.uninitialised {
    if (nodeType.hasInternalConstraints) {
      internalConstraints ??= ItemIoImpl.empty;
    }

    ProdLineNodeChangeTracker.newProdLineNode(
      this,
      _internalState,
      ProdLineNodeStateBuilder.initial(
        this,
        productionLine,
        internalConstraints,
      ),
    );
  }

  ProdLineNodeState get _state =>
      basePlanner.snapshotBuilder?.nodeTrackers[this]?.state ?? _internalState;

  @override
  void updateState(ProdLineNodeStateImpl newState) {
    basePlanner.throwIfMutationNotPermitted();
    _internalState = newState;
  }

  @override
  ProdLineNodeChangeTracker getChangeTracker() => basePlanner
      .getSnapshotBuilderOrThrow()
      .getProdLineChangeTracker(this, _internalState);

  @override
  ProdLineNodeStateBuilder getStateBuilder() => getChangeTracker().stateBuilder;

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
  void notifyListenersOfGeometryUpdate(NodeGeometry geometry) =>
      notifyListeners(ProdLineNodeEvent.geometryOp(geometry));

  @override
  void notifyListenersOfUpdate() {
    notifyListeners(const ProdLineNodeEvent());
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  String toString() => productionLine.toString();
}

class ProdLineNodeEvent extends NodeEvent {
  ProdLineNodeEvent.geometryOp(NodeGeometry super.geometry);

  const ProdLineNodeEvent();
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
