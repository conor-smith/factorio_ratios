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

  EdgeCartesianData _cartesianData;

  /* ---------------- Accessors ---------------- */
  double? get amount => _amount;
  ItemFlowDirection get flowDirection => edgeType.flowDirection;

  EdgeCartesianData get cartesianData => _cartesianData;
  LineType get lineType => _cartesianData.lineType;
  List<Line> get lines => _cartesianData.lines;

  bool get active => _active;

  /* --------------- Constructors --------------- */
  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double? initialAmount,
    required this.edgeType,
  }) : _eventHistory = parentGraph._eventHistory,
       _amount = initialAmount,
       _cartesianData = EdgeCartesianData.uninitialised,
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

        case EdgeEventType.newCartesianData:
          // TODO
          break;

        case EdgeEventType.addedToGraph:
          _active = true;

        case EdgeEventType.removedFromGraph:
          _active = false;
      }
    }
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

class EdgeCartesianData {
  final LineType lineType;
  // Goes from parent to child
  final List<Line> lines;

  static const uninitialised = EdgeCartesianData._(LineType.shortestPath, [
    Line.uninitialised,
  ]);

  const EdgeCartesianData._(this.lineType, this.lines);
}

class MutableEdgeCartesianData {
  LineType _lineType;
  final List<Line> _lines;

  LineType get lineType => _lineType;
  late final List<Line> lines = UnmodifiableListView(_lines);

  MutableEdgeCartesianData.from(EdgeCartesianData cartesianData)
    : _lineType = cartesianData.lineType,
      _lines = List.from(cartesianData.lines);
}

class Line {
  final Offset start, end;

  static const uninitialised = Line(Offset.zero, Offset.zero);

  const Line(this.start, this.end);
}
