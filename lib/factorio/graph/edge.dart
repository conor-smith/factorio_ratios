part of '../graph.dart';

class DirectedEdge with Stateful<EdgeEvent> {
  /* ------------- Immutable fields ------------- */
  final BaseGraph parentGraph;
  final _EventHistory _eventHistory;

  final ProdLineNode parent;
  final ProdLineNode child;
  final ItemData item;

  final Relationship edgeType;

  /* -------------- Mutable fields -------------- */
  bool _active;

  double? _amount;

  Side _parentConnection;
  Side _childConnection;
  LineType _lineType;
  // List must always be ordered from parent to child
  List<Offset> _lines;

  /* ----------- Delayed event fields ----------- */
  bool _performingDelayedEventOperation = false;

  /* ---------------- Accessors ---------------- */
  @override
  bool get performingDelayedEventOperation => _performingDelayedEventOperation;

  double? get amount => _amount;
  ItemFlowDirection get flowDirection => edgeType.flowDirection;
  Side get parentConnection => _parentConnection;
  Side get childConnection => _childConnection;
  LineType get lineType => _lineType;

  List<Offset> get lines => _lines;

  bool get active => _active;

  /* --------------- Constructors --------------- */
  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double? initialAmount,
    required this.edgeType,
    Side parentConnectionSide = Side.bottom,
    Side childConnectionSide = Side.top,
    LineType lineType = LineType.shortestPath,
  }) : _eventHistory = parentGraph._eventHistory,
       _childConnection = childConnectionSide,
       _parentConnection = parentConnectionSide,
       _amount = initialAmount,
       _lineType = lineType,
       _lines = const [Offset.zero, Offset.zero],
       _active = false {
    // TODO - fix up
    // Confirm both parent and child are valid
    if (parentGraph != parent.parentGraph || parentGraph != child.parentGraph) {
      throw const FactorioException(
        'Cannot connect two nodes from different graphs',
      );
    } else if (parent.parentOf.contains(this)) {
      throw const FactorioException('Cannot create duplicate edge');
    }

    // Ensure no loops are created
    // TODO - Allow loops
    Set<ProdLineNode> visitedNodes = {};
    List<ProdLineNode> nodesToVisit = child.parentOf
        .map((edge) => edge.child)
        .toList();
    while (nodesToVisit.isNotEmpty) {
      ProdLineNode node = nodesToVisit.removeLast();
      if (node == parent) {
        throw const FactorioException('Cannot create loop');
      } else if (!visitedNodes.contains(node)) {
        visitedNodes.add(node);
        nodesToVisit.addAll(node.parentOf.map((edge) => edge.child));
      }
    }

    parentGraph.apply(GraphEvent.newEdge(parentGraph, this));
    parent.apply(NodeEvent.newChildEdge(parent, this));
    child.apply(NodeEvent.newParentEdge(child, this));
    apply(EdgeEvent.addToGraph(this));
  }

  void removeFromGraph() {
    parentGraph.apply(GraphEvent.removeEdge(parentGraph, this));
    parent.apply(NodeEvent.removeChildEdge(parent, this));
    child.apply(NodeEvent.removeParentEdge(child, this));
    apply(EdgeEvent.removeFromGraph(this));
  }

  /* ------------- Stateful methods ------------- */
  @override
  void apply(EdgeEvent event) {
    _apply(event);

    _eventHistory.addEdgeEvent(event);
  }

  @override
  void redo(EdgeEvent event) {
    _apply(event);
  }

  @override
  void rollback(EdgeEvent event) {
    _apply(event.reversed);
  }

  void _apply(EdgeEvent event) {
    _eventHistory.checkIfMutationPermitted();

    for (var mutationEvent in event.mutations) {
      switch (mutationEvent) {
        case EdgeEventType.newAmount:
          _amount = event.newAmount;

        case EdgeEventType.newLines:
          _lineType = event.newLineType!;
          _parentConnection = event.newParentConnection!;
          _childConnection = event.newChildConnection!;
          _lines = event.newLines!;

        case EdgeEventType.addedToGraph:
          _active = true;

        case EdgeEventType.removedFromGraph:
          _active = false;
      }
    }
  }

  /* ---------- Delayed Event Methods ---------- */
  @override
  void cancelDelayedEventOperation() {
    // TODO: implement cancelDelayedEventOperation
  }

  @override
  void finishDelayedEventOperation() {
    // TODO: implement finishDelayedEventOperation
  }

  @override
  void startDelayedEventOperation() {
    // TODO: implement startDelayedEventOperation
  }

  /* ------------- All other logic ------------- */
}

// TODO - Add more linetypes
enum LineType { shortestPath }

enum ItemFlowDirection { parentToChild, childToParent }

enum Relationship {
  requestItems(ItemFlowDirection.childToParent),
  acceptExcess(ItemFlowDirection.childToParent);

  final ItemFlowDirection flowDirection;

  const Relationship(this.flowDirection);
}

enum Side { top, right, bottom, left }
