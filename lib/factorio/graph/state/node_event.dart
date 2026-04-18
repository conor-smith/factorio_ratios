part of '../../graph.dart';

class NodeEvent extends MutationEvent {
  final ProdLineNode node;

  final Set<NodeEventType> mutations;

  final NodeGeometry? oldGeometry, newGeometry;
  final ItemIo? oldRequirements, newRequirements;
  final NodeType? oldNodeType, newNodeType;
  final ProductionLine? oldProductionLine, newProductionLine;
  final Set<DirectedEdge> newChildOf,
      newParentOf,
      removedChildOf,
      removedParentOf;

  final NodeEvent? original;
  @override
  final bool isReversed;
  @override
  late final NodeEvent reversed = original ?? NodeEvent._reverse(this);

  NodeEvent.addToGraph(ProdLineNode node)
    : this._(node, {NodeEventType.addedToGraph});

  NodeEvent.removeFromGraph(ProdLineNode node)
    : this._(node, {NodeEventType.removedFromGraph});

  NodeEvent.updateGeometry(ProdLineNode node, NodeGeometry newGeometry)
    : this._(
        node,
        {NodeEventType.updateGeometry},
        oldGeometry: node.geometry,
        newGeometry: newGeometry,
      );

  NodeEvent.newRequirements(ProdLineNode node, ItemIo newRequirements)
    : this._(
        node,
        {NodeEventType.newRequirements},
        oldRequirements: node.requirements,
        newRequirements: newRequirements,
      );

  NodeEvent.clearRequirements(ProdLineNode node)
    : this._(node, {
        NodeEventType.newRequirements,
      }, oldRequirements: node.requirements);

  NodeEvent.newType(ProdLineNode node, NodeType newType)
    : this._(
        node,
        {NodeEventType.newNodeType},
        oldNodeType: node.nodeType,
        newNodeType: newType,
      );

  NodeEvent.newProductionLine(
    ProdLineNode node,
    ProductionLine newProductionLine,
  ) : this._(
        node,
        {NodeEventType.newProductionLine},
        oldProductionLine: node._line,
        newProductionLine: newProductionLine,
      );

  NodeEvent.newChildEdge(ProdLineNode node, DirectedEdge newChildEdge)
    : this._(node, {NodeEventType.parentOfUpdate}, newParentOf: {newChildEdge});

  NodeEvent.newParentEdge(ProdLineNode node, DirectedEdge newParentEdge)
    : this._(node, {NodeEventType.childOfUpdate}, newChildOf: {newParentEdge});

  NodeEvent.removeChildEdge(ProdLineNode node, DirectedEdge removedChildEdge)
    : this._(
        node,
        {NodeEventType.parentOfUpdate},
        removedParentOf: {removedChildEdge},
      );

  NodeEvent.removeParentEdge(ProdLineNode node, DirectedEdge removedParentEdge)
    : this._(
        node,
        {NodeEventType.childOfUpdate},
        removedChildOf: {removedParentEdge},
      );

  NodeEvent.tempGeometry(ProdLineNode node, NodeGeometry tempData)
    : this._(node, {NodeEventType.tempGeometry}, newGeometry: tempData);

  factory NodeEvent.combine(List<NodeEvent> orderedEvents) {
    Set<NodeEventType> mutations = {};

    Set<DirectedEdge> newParentOf = {};
    Set<DirectedEdge> removedParentOf = {};
    Set<DirectedEdge> newChildOf = {};
    Set<DirectedEdge> removedChildOf = {};

    NodeEvent? oldGeometryEvent, newGeometryEvent;
    NodeGeometry? oldGeometry, newGeometry;

    NodeEvent? oldNodeTypeEvent, newNodeTypeEvent;
    NodeType? oldNodeType, newNodeType;

    NodeEvent? oldRequirementsEvent, newRequirementsEvent;
    ItemIo? oldRequirements, newRequirements;

    NodeEvent? oldProdLineEvent, newProdLineEvent;
    ProductionLine? oldProdLine, newProdLine;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case NodeEventType.updateGeometry:
            oldGeometryEvent ??= event;
            newGeometryEvent = event;

          case NodeEventType.newRequirements:
            oldRequirementsEvent ??= event;
            newRequirementsEvent = event;

          case NodeEventType.newNodeType:
            oldNodeTypeEvent ??= event;
            newNodeTypeEvent = event;

          case NodeEventType.newProductionLine:
            oldProdLineEvent ??= event;
            newProdLineEvent = event;

          case NodeEventType.parentOfUpdate:
            newParentOf.addAll(event.newParentOf);
            removedParentOf.addAll(event.removedParentOf);

          case NodeEventType.childOfUpdate:
            newChildOf.addAll(event.newChildOf);
            removedChildOf.addAll(event.removedChildOf);

          case NodeEventType.addedToGraph:
          case NodeEventType.removedFromGraph:
            break;

          case NodeEventType.tempGeometry:
            throw const GraphException(
              'Cannot combine temp geometry node event',
            );
        }
      }
    }

    if (oldGeometryEvent != null) {
      oldGeometry = oldGeometryEvent.oldGeometry;
      newGeometry = newGeometryEvent!.newGeometry;
    }

    if (oldRequirementsEvent != null) {
      oldRequirements = oldRequirementsEvent.oldRequirements;
      newRequirements = newRequirementsEvent!.newRequirements;
    }

    if (oldNodeTypeEvent != null) {
      oldNodeType = oldNodeTypeEvent.oldNodeType;
      newNodeType = newNodeTypeEvent!.newNodeType;
    }

    if (oldProdLineEvent != null) {
      oldProdLine = oldProdLineEvent.oldProductionLine;
      newProdLine = newProdLineEvent!.newProductionLine;
    }

    _removedWhereBothContain(newParentOf, removedParentOf);
    _removedWhereBothContain(newChildOf, removedChildOf);

    if (mutations.containsAll(NodeEventType.creationEvents)) {
      mutations.removeAll(NodeEventType.creationEvents);
    }

    return NodeEvent._(
      orderedEvents.first.node,
      mutations,
      oldGeometry: oldGeometry,
      oldRequirements: oldRequirements,
      oldNodeType: oldNodeType,
      oldProductionLine: oldProdLine,
      removedParentOf: removedParentOf,
      removedChildOf: removedChildOf,
      newGeometry: newGeometry,
      newRequirements: newRequirements,
      newNodeType: newNodeType,
      newProductionLine: newProdLine,
      newParentOf: newParentOf,
      newChildOf: newChildOf,
    );
  }

  NodeEvent._(
    this.node,
    Set<NodeEventType> mutations, {
    ItemIo? oldRequirements,
    this.oldGeometry,
    this.oldNodeType,
    this.oldProductionLine,
    Set<DirectedEdge> removedParentOf = const {},
    Set<DirectedEdge> removedChildOf = const {},
    ItemIo? newRequirements,
    this.newGeometry,
    this.newNodeType,
    this.newProductionLine,
    Set<DirectedEdge> newParentOf = const {},
    Set<DirectedEdge> newChildOf = const {},
  }) : mutations = Set.unmodifiable(mutations),
       newRequirements = newRequirements != null
           ? Map.unmodifiable(newRequirements)
           : null,
       newParentOf = Set.unmodifiable(newParentOf),
       newChildOf = Set.unmodifiable(newChildOf),
       oldRequirements = oldRequirements != null
           ? Map.unmodifiable(oldRequirements)
           : null,
       removedParentOf = Set.unmodifiable(removedParentOf),
       removedChildOf = Set.unmodifiable(removedChildOf),
       isReversed = false,
       original = null;

  NodeEvent._reverse(NodeEvent toReverse)
    : node = toReverse.node,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldGeometry = toReverse.oldGeometry,
      oldRequirements = toReverse.newRequirements,
      oldNodeType = toReverse.newNodeType,
      oldProductionLine = toReverse.newProductionLine,
      removedParentOf = toReverse.newParentOf,
      removedChildOf = toReverse.newChildOf,
      newGeometry = toReverse.newGeometry,
      newRequirements = toReverse.oldRequirements,
      newNodeType = toReverse.oldNodeType,
      newProductionLine = toReverse.oldProductionLine,
      newParentOf = toReverse.removedParentOf,
      newChildOf = toReverse.removedChildOf,
      isReversed = true,
      original = toReverse;
}

enum NodeEventType {
  updateGeometry,
  tempGeometry,
  newRequirements,
  newNodeType,
  newProductionLine,
  parentOfUpdate,
  childOfUpdate,
  addedToGraph,
  removedFromGraph;

  NodeEventType get reverse => switch (this) {
    updateGeometry => updateGeometry,
    tempGeometry => tempGeometry,
    newRequirements => newRequirements,
    newNodeType => newNodeType,
    newProductionLine => newProductionLine,
    parentOfUpdate => parentOfUpdate,
    childOfUpdate => childOfUpdate,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<NodeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}
