part of 'node.dart';

class ProdLineNode extends NodeElement<ProdLineNodeState, NodeEvent>
    with EventNotifier<NodeEvent> {
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
  ProductionLineIoData get ioData {
    basePlanner.throwIfIoNotToBeAccessed(this);
    return state.ioData;
  }

  @override
  ItemIo get edgeConstraints {
    basePlanner.throwIfIoNotToBeAccessed(this);
    return state.edgeConstraints;
  }

  @override
  ItemIo get itemIo {
    basePlanner.throwIfIoNotToBeAccessed(this);
    return state.itemIo;
  }

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
  bool traverseDepsAndUpdateIo(Set<BasePlannerElement> visitedElements) {
    // Check for circular dependency
    // TODO - Centralise this code rather than copying it
    if (visitedElements.contains(this)) {
      throw BasePlannerException('Circular dependency detected at $this');
    }

    visitedElements.add(this);

    var hasBeenUpdated = switch (basePlanner
        .getSnapshotBuilder()
        .getUpdateStatus(this)) {
      UpdateStatus.completeUpdate => true,
      UpdateStatus.completeNoUpdate => false,
      UpdateStatus.checkDependencies => _determineIo(false, visitedElements),
      UpdateStatus.required => _determineIo(true, visitedElements),
    };

    visitedElements.remove(this);
    return hasBeenUpdated;
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

  bool _determineIo(bool forceUpdate, Set<BasePlannerElement> visitedElements) {
    ItemIoImpl constraints;
    var snapshotBuilder = basePlanner.getSnapshotBuilder();

    if (nodeType.hasInternalConstraints) {
      constraints = internalConstraints!;
    } else {
      var parentDeps = allParents.where(
        (edge) => edge.edgeType == EdgeType.requestItems,
      );
      var childDeps = allChildren.where(
        (edge) => edge.edgeType == EdgeType.pushExcess,
      );

      bool depUpdate = [...parentDeps, ...childDeps]
          .map((depEdge) => depEdge.traverseDepsAndUpdateIo(visitedElements))
          .fold(false, (update1, update2) => update1 || update2);

      if (!depUpdate && !forceUpdate) {
        snapshotBuilder.updateIoSatus(this, UpdateStatus.completeNoUpdate);
        return false;
      } else {
        constraints = _calculateEdgeConstraints();
        getStateBuilder().updateEdgeConstraints(constraints);
      }
    }

    snapshotBuilder.updateIoSatus(parentGraph, UpdateStatus.required);
    var newItemIo = productionLine.calculateItemIo(constraints);
    getStateBuilder().updateIo(newItemIo);

    snapshotBuilder.updateIoSatus(this, UpdateStatus.completeUpdate);

    var parentDependants = allParents.where(
      (edge) => edge.edgeType != EdgeType.requestItems,
    );
    var childDependants = allChildren.where(
      (edge) => edge.edgeType != EdgeType.pushExcess,
    );

    for (BasePlannerElement dependant in [
      ...parentDependants,
      ...childDependants,
      parentGraph,
    ]) {
      snapshotBuilder.updateIoSatus(dependant, UpdateStatus.required);
    }

    return true;
  }

  ItemIoImpl _calculateEdgeConstraints() {
    ItemIoBuilder builder = ItemIoBuilder();

    parents.forEach((item, edges) {
      var requestedAmount = edges
          .where((edge) => edge.edgeType == EdgeType.requestItems)
          .fold(0.0, (sum, edge) => sum + edge.amount);

      if (requestedAmount != 0) {
        builder.addToOutputs(item, requestedAmount);
      }
    });

    children.forEach((item, edges) {
      var pushedAmount = edges
          .where((edge) => edge.edgeType == EdgeType.pushExcess)
          .fold(0.0, (sum, edge) => sum + edge.amount);

      if (pushedAmount != 0) {
        builder.addToInputs(item, pushedAmount);
      }
    });

    return builder.build();
  }

  @override
  String toString() => productionLine.toString();
}
