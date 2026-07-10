part of 'node.dart';

class ProdLineNode extends NodeElement<ProdLineNodeState, NodeEvent> {
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

  ProductionLine get productionLine => state.productionLine;

  @override
  ItemIoImpl get ioRatios => productionLine.ioRatios;
  @override
  ProductionLineType get productionLineType =>
      productionLine.productionLineType;
  @override
  Set<InGameItem> get inputItems => productionLine.inputItems;
  @override
  Set<InGameItem> get outputItems => productionLine.outputItems;

  @override
  ProductionLineIoData get ioData => state.ioData;

  ProdLineNodeStateImpl _internalState;
  ProdLineNodeStateBuilder? _stateBuilder;

  ProdLineNode.addToBasePlanner(
    super.basePlanner, {
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
  }) : _internalState = ProdLineNodeStateImpl.uninitialised {
    _stateBuilder = ProdLineNodeStateBuilder.initial(this, productionLine);
  }

  ProdLineNodeState get state => _stateBuilder ?? _internalState;

  @override
  void updateState(ProdLineNodeStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();
    _stateBuilder = null;
    _internalState = state;
  }

  @override
  ProdLineNodeStateBuilder getStateBuilder() {
    _stateBuilder ??= ProdLineNodeStateBuilder.from(this, _internalState);

    return _stateBuilder!;
  }

  @override
  void cancelStateBuilder() => _stateBuilder = null;

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
  NodeDependencies determineDependencies() {
    Map<InGameItem, Set<Edge>> parentDeps = Map.from(parents)
      ..updateAll(
        (item, edgeSet) => edgeSet
            .where((edge) => edge.edgeType == EdgeType.requestItems)
            .toSet(),
      )
      ..removeWhere((item, edgeSet) => edgeSet.isEmpty);

    Map<InGameItem, Set<Edge>> childDeps = Map.from(children)
      ..updateAll(
        (item, edgeSet) => edgeSet
            .where((edge) => edge.edgeType == EdgeType.pushExcess)
            .toSet(),
      )
      ..removeWhere((item, edgeSet) => edgeSet.isEmpty);

    return NodeDependencies(parentDeps: parentDeps, childDeps: childDeps);
  }

  @override
  List<BasePlannerElement> determineDependants() {
    var parentDependants = allParents.where(
      (parent) => parent.edgeType != EdgeType.requestItems,
    );
    var childDependants = allChildren.where(
      (child) => child.edgeType != EdgeType.pushExcess,
    );

    return [...parentDependants, ...childDependants, parentGraph];
  }

  // TODO - Actually check if an upate occurs rather than always returning true
  @override
  bool calculateIo(NodeDependencies dependencies) {
    ItemIoImpl constraints;

    if (nodeType.hasInternalConstraints) {
      constraints = internalConstraints!;
    } else {
      constraints = _calculateEdgeConstraints(dependencies);
      getStateBuilder().updateEdgeConstraints(constraints);
    }

    // Check if update is required
    // This will only occur if constraints or production line are different
    if (constraints != _internalState.ioData.constraints ||
        productionLine != _internalState.productionLine) {
      var newIoData = productionLine.calculateIoData(constraints);

      getStateBuilder().updateIoData(newIoData);
      basePlanner.getSnapshotBuilder().queueUnusedIoCheck(this);

      if (nodeType.isIo) {
        basePlanner.getSnapshotBuilder().queueUnusedIoCheck(parentGraph);
      }

      return true;
    } else {
      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  ItemIoImpl _calculateEdgeConstraints(NodeDependencies dependencies) {
    ItemIoBuilder builder = ItemIoBuilder();

    dependencies.parentDeps.forEach((item, requestItemEdges) {
      builder.addToOutputs(
        item,
        requestItemEdges
            .map((edge) => edge.amount)
            .reduce((amount1, amount2) => amount1 + amount2),
      );
    });

    dependencies.childDeps.forEach((item, pushExcessEdges) {
      builder.addToInputs(
        item,
        pushExcessEdges
            .map((edge) => edge.amount)
            .reduce((amount1, amount2) => amount1 + amount2),
      );
    });

    return builder.build();
  }

  @override
  String toString() => productionLine.toString();
}

class NodeDependencies implements Dependencies {
  final Map<InGameItem, Set<Edge>> childDeps;
  final Map<InGameItem, Set<Edge>> parentDeps;

  NodeDependencies({required this.childDeps, required this.parentDeps});

  @override
  Iterable<Edge> get allDependencies => childDeps.values
      .followedBy(parentDeps.values)
      .expand((edgeSet) => edgeSet);
}
