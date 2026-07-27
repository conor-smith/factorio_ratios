part of 'change_trackers.dart';

class EdgeChangeTracker
    extends
        ElementChangeTracker<
          Edge,
          EdgeStateImpl,
          EdgeDependencies,
          EdgeStateBuilder
        > {
  EdgeChangeTracker(super.element, super.previousState);

  EdgeChangeTracker.newEdge(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : super.newElement() {
    element.parentGraph.getStateBuilder()._edges.add(element);

    element.parentProdLine.getStateBuilder()._children.update(
      element.item,
      (edges) => edges..add(element),
      ifAbsent: () => {element},
    );

    element.childProdLine.getStateBuilder()._parents.update(
      element.item,
      (edges) => edges..add(element),
      ifAbsent: () => {element},
    );

    _updateParentIfParentIsGraphNode();
    _updateChildIfChildIsGraphNode();
  }

  @override
  EdgeState get state => _cachedStateBuilder ?? previousState;

  @override
  void removeSelf() {
    _removeSelfAndUpdateParentGraph();

    element.parentProdLine.getStateBuilder()._children[element.item]!.remove(
      element,
    );
    element.childProdLine.getStateBuilder()._parents[element.item]!.remove(
      element,
    );

    _updateParentIfParentIsGraphNode();
    _updateChildIfChildIsGraphNode();

    for (var dependant in _determineDependants()) {
      dependant.getChangeTracker().queueIoUpdate();
    }

    _removeSelfOnly();
  }

  @override
  void _addSelfToSnapshotBuilder() {
    snapshotBuilder._edgeTrackers[element] = this;
    snapshotBuilder.allTrackers.add(this);
  }

  @override
  bool _calculateIo() {
    double newAmount;
    List<NodeElement> unusedIoCheckNodes;

    switch (element.edgeType) {
      case EdgeType.requestItems:
        newAmount = _getAmountToRequest() * element.percentage;
        unusedIoCheckNodes = [element.parentProdLine, element.parentNode];

      case EdgeType.pushExcess:
        newAmount = _getAmountToPush() * element.percentage;
        unusedIoCheckNodes = [element.childProdLine, element.childNode];

      case EdgeType.requestExcess:
        var request = _getAmountToRequest();
        var push = _getAmountToPush();
        newAmount = request > push ? request : push;

        unusedIoCheckNodes = [
          element.parentProdLine,
          element.parentNode,
          element.childProdLine,
          element.childNode,
        ];
    }

    if (newAmount != state.amount) {
      stateBuilder._updateAmount(newAmount);

      for (var node in unusedIoCheckNodes) {
        node.getChangeTracker().queueUnusedIoCheck();
      }

      return true;
    } else {
      return false;
    }
  }

  @override
  EdgeStateBuilder _createStateBuilder() =>
      EdgeStateBuilder.from(element, previousState);

  @override
  Iterable<BasePlannerElement> _determineDependants() =>
      _determineParentDependants().followedBy(_determineChildDependants());

  @override
  EdgeDependencies _determineDependencies() => switch (element.edgeType) {
    EdgeType.requestItems => EdgeDependencies(
      parentProdLineDep: element.parentProdLine,
      parentEdgeDeps: element.parentNode.children[element.item]!
          .where((edge) => edge.edgeType != EdgeType.requestItems)
          .toList(),
    ),

    EdgeType.pushExcess => EdgeDependencies(
      childProdLineDep: element.childProdLine,
      childEdgeDeps: element.childNode.parents[element.item]!
          .where((edge) => edge.edgeType == EdgeType.pushExcess)
          .toList(),
    ),

    EdgeType.requestExcess => EdgeDependencies(
      parentProdLineDep: element.parentProdLine,
      parentEdgeDeps: element.parentNode.children[element.item]!
          .where(
            (edge) =>
                edge.edgeType == EdgeType.pushExcess ||
                (edge.edgeType == EdgeType.requestExcess &&
                    edge.parentPriority < element.parentPriority),
          )
          .toList(),
      childProdLineDep: element.childProdLine,
      childEdgeDeps: element.childNode.parents[element.item]!
          .where(
            (edge) =>
                edge.edgeType != EdgeType.requestItems ||
                (edge.edgeType == EdgeType.requestExcess &&
                    edge.childPriority < element.childPriority),
          )
          .toList(),
    ),
  };

  @override
  void _removeSelfOnly() {
    _queuedForRemoval = true;
  }

  void _removeSelfFromParentOnly() {
    _removeSelfAndUpdateParentGraph();

    element.parentProdLine.children[element.item]!.remove(element);

    _updateParentIfParentIsGraphNode();

    for (var parentDependant in _determineParentDependants()) {
      parentDependant.getChangeTracker().queueIoUpdate();
    }

    _removeSelfOnly();
  }

  void _removeSelfFromChildOnly() {
    _removeSelfAndUpdateParentGraph();

    element.childProdLine.parents[element.item]!.remove(element);

    _updateChildIfChildIsGraphNode();

    for (var childDependant in _determineChildDependants()) {
      childDependant.getChangeTracker().queueIoUpdate();
    }

    _removeSelfOnly();
  }

  List<BasePlannerElement> _determineParentDependants() =>
      switch (element.edgeType) {
        EdgeType.requestItems => const [],

        EdgeType.pushExcess => [
          element.parentProdLine,
          element.parentNode,
          ...element.parentProdLine.children[element.item]!.where(
            (edge) => edge.edgeType != EdgeType.pushExcess,
          ),
        ],

        EdgeType.requestExcess => [
          element.parentProdLine,
          element.parentNode,
          ...element.parentProdLine.children[element.item]!.where(
            (edge) =>
                edge.edgeType == EdgeType.pushExcess ||
                (edge.edgeType == EdgeType.requestExcess &&
                    edge.childPriority > element.childPriority),
          ),
        ],
      };

  List<BasePlannerElement> _determineChildDependants() =>
      switch (element.edgeType) {
        EdgeType.requestItems => [
          element.childProdLine,
          element.childNode,
          ...element.childProdLine.parents[element.item]!.where(
            (edge) => edge.edgeType != EdgeType.requestItems,
          ),
        ],

        EdgeType.pushExcess => const [],

        EdgeType.requestExcess => [
          element.childProdLine,
          element.childNode,
          ...element.childProdLine.parents[element.item]!.where(
            (edge) =>
                edge.edgeType == EdgeType.requestItems ||
                (edge.edgeType == EdgeType.requestExcess &&
                    edge.parentPriority > element.parentPriority),
          ),
        ],
      };

  void _updateParentIfParentIsGraphNode() {
    if (element.parentNode is Graph) {
      (element.parentNode as Graph)
        ..getStateBuilder()._cachedChildren = null
        ..getChangeTracker().queueIoUpdate();
    }
  }

  void _updateChildIfChildIsGraphNode() {
    if (element.childNode is Graph) {
      (element.childNode as Graph)
        ..getStateBuilder()._cachedParents = null
        ..getChangeTracker().queueIoUpdate();
    }
  }

  void _removeSelfAndUpdateParentGraph() => element.parentGraph
    ..getChangeTracker().queueLayoutUpdate()
    ..getStateBuilder()._edges.remove(element);

  double _getAmountToRequest() =>
      _getCachedDependencies().parentProdLineDep!.ioData.itemIo.inputs[element
          .item]! -
      _getCachedDependencies().orderedParentEdgeDeps!.fold(
        0.0,
        (amount, edge) => amount + edge.amount,
      );

  double _getAmountToPush() =>
      _getCachedDependencies().childProdLineDep!.ioData.itemIo.outputs[element
          .item]! -
      _getCachedDependencies().orderedChildEdgeDeps!.fold(
        0.0,
        (amount, edge) => amount + edge.amount,
      );
}

class EdgeDependencies implements Dependencies {
  final ProdLineNode? parentProdLineDep;
  final List<Edge>? orderedParentEdgeDeps;

  final ProdLineNode? childProdLineDep;
  final List<Edge>? orderedChildEdgeDeps;

  EdgeDependencies({
    this.parentProdLineDep,
    List<Edge>? parentEdgeDeps,
    this.childProdLineDep,
    List<Edge>? childEdgeDeps,
  }) : orderedParentEdgeDeps = parentEdgeDeps,
       orderedChildEdgeDeps = childEdgeDeps {
    orderedParentEdgeDeps?.sort(
      (preEdge1, preEdge2) =>
          preEdge1.parentPriority.compareTo(preEdge2.parentPriority),
    );
    orderedChildEdgeDeps?.sort(
      (creEdge1, creEdge2) =>
          creEdge1.childPriority.compareTo(creEdge2.childPriority),
    );
  }

  @override
  Iterable<BasePlannerElement> get allElements => <BasePlannerElement?>[
    parentProdLineDep,
    childProdLineDep,
    ...?orderedParentEdgeDeps,
    ...?orderedChildEdgeDeps,
  ].nonNulls;
}
