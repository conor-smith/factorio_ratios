part of '../graph.dart';

class DirectedEdge with Stateful<EdgeEvent> {
  final BaseGraph parentGraph;
  final ItemData item;

  final ProdLineNode parent;
  final ProdLineNode child;

  final Relationship edgeType;
  double? _amount;

  // Value must be from 0 to 1
  // TODO - verification
  double _percentage;

  Side _parentConnection;
  Side _childConnection;
  LineType _lineType;
  // List must always be ordered from parent to child
  List<Offset> _lines;

  double? get amount => _amount;
  double get percentage => _percentage;
  ItemFlowDirection get flowDirection => edgeType.flowDirection;
  Side get parentConnection => _parentConnection;
  Side get childConnection => _childConnection;
  LineType get lineType => _lineType;

  List<Offset> get lines => _lines;

  bool _active;

  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double? initialAmount,
    double percentage = 1,
    required this.edgeType,
    Side parentConnectionSide = Side.bottom,
    Side childConnectionSide = Side.top,
    LineType lineType = LineType.shortestPath,
  }) : _childConnection = childConnectionSide,
       _parentConnection = parentConnectionSide,
       _amount = initialAmount,
       _lineType = lineType,
       _percentage = percentage,
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

  // TODO - It has to be possible to do this without repeating myself this much
  void updateParentPosition() {
    List<Offset> newLines = List.from(lines);
    var rect = parent._rect;
    switch (lineType) {
      case LineType.shortestPath:
        switch (parentConnection) {
          case Side.top:
            newLines[0] = Offset(rect.left + (rect.width / 2), rect.top);
          case Side.right:
            newLines[0] = Offset(rect.right, rect.top + (rect.height / 2));
          case Side.bottom:
            newLines[0] = Offset(rect.left + (rect.width / 2), rect.bottom);
          case Side.left:
            newLines[0] = Offset(rect.left, rect.top + (rect.height / 2));
        }
    }

    apply(
      EdgeEvent.updateLines(this, newLines, parentConnection, childConnection),
    );
  }

  void updateChildPosition() {
    List<Offset> newLines = List.from(lines);
    var rect = child._rect;
    switch (lineType) {
      case LineType.shortestPath:
        switch (parentConnection) {
          case Side.top:
            newLines[1] = Offset(rect.left + (rect.width / 2), rect.top);
          case Side.right:
            newLines[1] = Offset(rect.right, rect.top + (rect.height / 2));
          case Side.bottom:
            newLines[1] = Offset(rect.left + (rect.width / 2), rect.bottom);
          case Side.left:
            newLines[1] = Offset(rect.left, rect.top + (rect.height / 2));
        }
    }

    apply(
      EdgeEvent.updateLines(this, newLines, parentConnection, childConnection),
    );
  }

  @override
  void apply(EdgeEvent event) {
    _apply(event);

    parentGraph._eventHistory.addEdgeEvent(event);
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
    parentGraph._eventHistory.checkIfMutationPermitted();

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
