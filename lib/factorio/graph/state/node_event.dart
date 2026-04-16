part of '../../graph.dart';

class NodeEvent extends MutationEvent {
  final ProdLineNode node;

  final Set<NodeEventType> mutations;

  final NodeCartesianData? oldCartesianData, newCartesianData;
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

  NodeEvent.updatePosition(
    ProdLineNode node,
    NodeCartesianData newCartesianData,
  ) : this._(
        node,
        {NodeEventType.newPosition},
        oldCartesianData: node.cartesianData,
        newCartesianData: newCartesianData,
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

  NodeEvent.tempPosition(ProdLineNode node, NodeCartesianData tempData)
    : this._(node, {NodeEventType.tempPosition}, newCartesianData: tempData);

  factory NodeEvent.combine(List<NodeEvent> orderedEvents) {
    Set<NodeEventType> mutations = {};

    Set<DirectedEdge> newParentOf = {};
    Set<DirectedEdge> removedParentOf = {};
    Set<DirectedEdge> newChildOf = {};
    Set<DirectedEdge> removedChildOf = {};

    NodeEvent? oldCartesianEvent, newCartesianEvent;
    NodeCartesianData? oldCartesianData, newCartesianData;

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
          case NodeEventType.newPosition:
            oldCartesianEvent ??= event;
            newCartesianEvent = event;

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

          case NodeEventType.tempPosition:
            throw const GraphException(
              'Cannot combine temp position node event',
            );
        }
      }
    }

    if (oldCartesianEvent != null) {
      oldCartesianData = oldCartesianEvent.oldCartesianData;
      newCartesianData = newCartesianEvent!.newCartesianData;
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
      oldCartesianData: oldCartesianData,
      oldRequirements: oldRequirements,
      oldNodeType: oldNodeType,
      oldProductionLine: oldProdLine,
      removedParentOf: removedParentOf,
      removedChildOf: removedChildOf,
      newCartesianData: newCartesianData,
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
    this.oldCartesianData,
    this.oldNodeType,
    this.oldProductionLine,
    Set<DirectedEdge> removedParentOf = const {},
    Set<DirectedEdge> removedChildOf = const {},
    ItemIo? newRequirements,
    this.newCartesianData,
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
      oldCartesianData = toReverse.oldCartesianData,
      oldRequirements = toReverse.newRequirements,
      oldNodeType = toReverse.newNodeType,
      oldProductionLine = toReverse.newProductionLine,
      removedParentOf = toReverse.newParentOf,
      removedChildOf = toReverse.newChildOf,
      newCartesianData = toReverse.newCartesianData,
      newRequirements = toReverse.oldRequirements,
      newNodeType = toReverse.oldNodeType,
      newProductionLine = toReverse.oldProductionLine,
      newParentOf = toReverse.removedParentOf,
      newChildOf = toReverse.removedChildOf,
      isReversed = true,
      original = toReverse;
}

enum NodeEventType {
  newPosition,
  tempPosition,
  newRequirements,
  newNodeType,
  newProductionLine,
  parentOfUpdate,
  childOfUpdate,
  addedToGraph,
  removedFromGraph;

  NodeEventType get reverse => switch (this) {
    newPosition => newPosition,
    tempPosition => tempPosition,
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
