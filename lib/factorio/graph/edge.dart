part of 'graph.dart';

/// Represents a flow of items between two [ProdLineNode] objects in the graph.
///
/// Every edge has a [parent] and a [child].
/// However, it should be known that parent isn't necessarily the consumer
/// of the child's outputs.
/// Rather, relationships are determined by which node can set constraints on the other.
/// While the majority of parents will be consumers of their children's outputs,
/// there are certain scenarios the parent is a producer.
///
/// Eg. In the actual game of factorio, producing molten iron from lava also produces stone.
/// If this stone is not disposed of, the production line backs up and iron cannot
/// be produced.
/// In this application, this would be represented by an edge of type
/// [Relationship.acceptExcess], sending excess stone to another node and setting
/// an input constraint.
class DirectedEdge with Stateful<EdgeEvent> {
  /* ------------- Immutable fields ------------- */
  final PlanetBaseGraph parentGraph;
  final _EventHistory _eventHistory;

  final ProdLineNode parent;
  final ProdLineNode child;
  final InGameItem item;

  final Relationship edgeType;

  /* -------------- Mutable fields -------------- */
  double? _amount;

  EdgeGeometry _geometry;

  /* ---------------- Accessors ---------------- */
  double? get amount => _amount;
  ItemFlowDirection get flowDirection => edgeType.flowDirection;

  EdgeGeometry get geometry => _geometry;
  LineType get lineType => _geometry.lineType;
  List<Line> get lines => _geometry.lines;

  bool get selected => parentGraph.globalData._selectedEdges.contains(this);

  /* --------------- Constructors --------------- */
  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double? initialAmount,
    required this.edgeType,
  }) : _eventHistory = parentGraph._history,
       _amount = initialAmount,
       _geometry = EdgeGeometry.uninitialised {
    // TODO - fix up
    // Confirm both parent and child are valid
    if (parentGraph != parent.parentGraph || parentGraph != child.parentGraph) {
      throw const FactorioException(
        'Cannot connect two nodes from different graphs',
      );
    } else if (parent.children.contains(this)) {
      throw const FactorioException('Cannot create duplicate edge');
    }

    // Ensure no loops are created
    // TODO - Allow loops
    Set<ProdLineNode> visitedNodes = {};
    List<ProdLineNode> nodesToVisit = child.children
        .map((edge) => edge.child)
        .toList();
    while (nodesToVisit.isNotEmpty) {
      ProdLineNode node = nodesToVisit.removeLast();
      if (node == parent) {
        throw const FactorioException('Cannot create loop');
      } else if (!visitedNodes.contains(node)) {
        visitedNodes.add(node);
        nodesToVisit.addAll(node.children.map((edge) => edge.child));
      }
    }

    parentGraph.apply(GraphEvent.newEdge(parentGraph, this));
    parent.apply(NodeEvent.newChildEdge(parent, this));
    child.apply(NodeEvent.newParentEdge(child, this));
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

        case EdgeEventType.newGeometry:
          _geometry = event.newGeometry!;

        case EdgeEventType.tempGeometry:
        case EdgeEventType.selectToggle:
          throw const MutationException('Cannot apply temp edge event');
      }
    }
  }

  /* ------------- All other logic ------------- */
  void removeFromGraphAndNodes() {
    parentGraph.apply(GraphEvent.removeEdge(parentGraph, this));
    parent.apply(NodeEvent.removeChildEdge(parent, this));
    child.apply(NodeEvent.removeParentEdge(child, this));
  }

  void _removeFromParentOnly() {
    parent.apply(NodeEvent.removeChildEdge(parent, this));
  }

  void _removeFromChildOnly() {
    child.apply(NodeEvent.removeParentEdge(child, this));
  }

  void _shortestLineBetweenNodes() {
    apply(EdgeEvent.updateGeometry(this, EdgeGeometry.shortestPath(this)));
  }
}

// TODO - Add more linetypes
enum LineType { shortestPath }

enum ItemFlowDirection { parentToChild, childToParent }

enum Relationship {
  requestItems(ItemFlowDirection.childToParent),
  acceptExcess(ItemFlowDirection.parentToChild);

  final ItemFlowDirection flowDirection;

  const Relationship(this.flowDirection);
}
