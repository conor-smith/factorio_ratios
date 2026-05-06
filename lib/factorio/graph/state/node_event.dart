part of 'state.dart';

class NodeEvent extends MutationEvent {
  final ProdLineNode node;

  final Set<NodeEventType> mutations;

  final ProductionLineIo? oldIo, newIo;
  final NodeGeometry? oldGeometry, newGeometry;
  final ProductionLine? oldProductionLine, newProductionLine;
  final List<DirectedEdge>? oldChildOf, oldParentOf, newChildOf, newParentOf;
  final ItemIo? oldInputConstraints,
      oldOutputConstraints,
      newInputConstraints,
      newOutputConstraints;

  final NodeEvent? original;
  @override
  final bool isReversed;
  @override
  late final NodeEvent reversed = original ?? NodeEvent._reverse(this);

  NodeEvent.addToGraph(ProdLineNode node)
    : this._(node, const {NodeEventType.addedToGraph});

  NodeEvent.removeFromGraph(ProdLineNode node)
    : this._(
        node,
        const {
          NodeEventType.removedFromGraph,
          NodeEventType.parentOfUpdate,
          NodeEventType.childOfUpdate,
        },
        oldParentOf: node.parentOf,
        oldChildOf: node.childOf,
        newParentOf: const [],
        newChildOf: const [],
      );

  NodeEvent.updateGeometry(ProdLineNode node, NodeGeometry newGeometry)
    : this._(
        node,
        const {NodeEventType.updateGeometry},
        oldGeometry: node.geometry,
        newGeometry: newGeometry,
      );

  NodeEvent.newProductionLine(
    ProdLineNode node,
    ProductionLine newProductionLine,
  ) : this._(
        node,
        const {NodeEventType.newProductionLine},
        oldProductionLine: node.productionLine,
        newProductionLine: newProductionLine,
      );

  NodeEvent.newIo(ProdLineNode node, ProductionLineIo newIo)
    : this._(
        node,
        const {NodeEventType.updateIo},
        oldIo: node.ioData,
        newIo: newIo,
      );

  NodeEvent.clearIo(ProdLineNode node)
    : this._(node, const {NodeEventType.updateIo}, oldIo: node.ioData);

  NodeEvent.newInternalConstraints(
    ProdLineNode node, {
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
  }) : this._(
         node,
         const {NodeEventType.updateConstraints},
         oldInputConstraints: node.internalInputConstraints,
         oldOutputConstraints: node.internalOutputConstraints,
         newInputConstraints: inputConstraints,
         newOutputConstraints: outputConstraints,
       );

  NodeEvent.clearInternalConstraints(ProdLineNode node)
    : this._(
        node,
        const {NodeEventType.updateConstraints},
        oldInputConstraints: node.internalInputConstraints,
        oldOutputConstraints: node.internalOutputConstraints,
      );

  NodeEvent.newChildEdge(ProdLineNode node, DirectedEdge newChildEdge)
    : this._(
        node,
        const {NodeEventType.parentOfUpdate},
        oldParentOf: node.parentOf,
        newParentOf: [...node.parentOf, newChildEdge],
      );

  NodeEvent.newParentEdge(ProdLineNode node, DirectedEdge newParentEdge)
    : this._(
        node,
        const {NodeEventType.childOfUpdate},
        oldChildOf: node.childOf,
        newChildOf: [...node.childOf, newParentEdge],
      );

  NodeEvent.removeChildEdge(ProdLineNode node, DirectedEdge removedChildEdge)
    : this._(
        node,
        const {NodeEventType.parentOfUpdate},
        oldParentOf: node.parentOf,
        newParentOf: List.from(node.parentOf)..remove(removedChildEdge),
      );

  NodeEvent.removeParentEdge(ProdLineNode node, DirectedEdge removedParentEdge)
    : this._(
        node,
        const {NodeEventType.childOfUpdate},
        oldChildOf: node.childOf,
        newChildOf: List.from(node.childOf)..remove(removedParentEdge),
      );

  NodeEvent.tempGeometry(ProdLineNode node, NodeGeometry tempData)
    : this._(node, const {NodeEventType.tempGeometry}, newGeometry: tempData);

  factory NodeEvent.combine(List<NodeEvent> orderedEvents) {
    Set<NodeEventType> mutations = {};

    NodeEvent? oldGeometryEvent, newGeometryEvent;
    NodeEvent? oldIoEvent, newIoEvent;
    NodeEvent? oldConstraintsEvent, newConstraintsEvent;
    NodeEvent? oldProdLineEvent, newProdLineEvent;
    NodeEvent? oldParentOfEvent, newParentOfEvent;
    NodeEvent? oldChildOfEvent, newChildOfEvent;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case NodeEventType.updateGeometry:
            oldGeometryEvent ??= event;
            newGeometryEvent = event;

          case NodeEventType.updateIo:
            oldIoEvent ??= event;
            newIoEvent = event;

          case NodeEventType.updateConstraints:
            oldConstraintsEvent ??= event;
            newConstraintsEvent = event;

          case NodeEventType.newProductionLine:
            oldProdLineEvent ??= event;
            newProdLineEvent = event;

          case NodeEventType.parentOfUpdate:
            oldParentOfEvent ??= event;
            newParentOfEvent = event;

          case NodeEventType.childOfUpdate:
            oldChildOfEvent ??= event;
            newChildOfEvent = event;

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

    if (mutations.containsAll(NodeEventType.creationEvents)) {
      mutations.removeAll(NodeEventType.creationEvents);
    }

    return NodeEvent._(
      orderedEvents.first.node,
      mutations,
      oldGeometry: oldGeometryEvent?.oldGeometry,
      oldIo: oldIoEvent?.oldIo,
      oldProductionLine: oldProdLineEvent?.oldProductionLine,
      oldInputConstraints: oldConstraintsEvent?.oldInputConstraints,
      oldOutputConstraints: oldConstraintsEvent?.oldOutputConstraints,
      oldParentOf: oldParentOfEvent?.oldParentOf,
      oldChildOf: oldChildOfEvent?.oldChildOf,
      newGeometry: newGeometryEvent?.newGeometry,
      newIo: newIoEvent?.newIo,
      newProductionLine: newProdLineEvent?.newProductionLine,
      newInputConstraints: newConstraintsEvent?.newInputConstraints,
      newOutputConstraints: newConstraintsEvent?.newOutputConstraints,
      newParentOf: newParentOfEvent?.newParentOf,
      newChildOf: newChildOfEvent?.newChildOf,
    );
  }

  NodeEvent._(
    this.node,
    Set<NodeEventType> mutations, {
    this.oldIo,
    this.oldProductionLine,
    this.oldInputConstraints,
    this.oldOutputConstraints,
    this.oldChildOf,
    this.oldParentOf,
    this.oldGeometry,
    this.newProductionLine,
    this.newIo,
    ItemIo? newInputConstraints,
    ItemIo? newOutputConstraints,
    Iterable<DirectedEdge>? newParentOf,
    Iterable<DirectedEdge>? newChildOf,
    this.newGeometry,
  }) : mutations = Set.unmodifiable(mutations),
       newInputConstraints = _unmodifiableOrNullMap(newInputConstraints),
       newOutputConstraints = _unmodifiableOrNullMap(newOutputConstraints),
       newParentOf = _unmodifiableOrNullList(newParentOf),
       newChildOf = _unmodifiableOrNullList(newChildOf),
       isReversed = false,
       original = null;

  NodeEvent._reverse(NodeEvent toReverse)
    : node = toReverse.node,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldIo = toReverse.newIo,
      oldGeometry = toReverse.newGeometry,
      oldInputConstraints = toReverse.newInputConstraints,
      oldOutputConstraints = toReverse.newOutputConstraints,
      oldProductionLine = toReverse.newProductionLine,
      oldParentOf = toReverse.newParentOf,
      oldChildOf = toReverse.newChildOf,
      newIo = toReverse.oldIo,
      newGeometry = toReverse.oldGeometry,
      newInputConstraints = toReverse.oldInputConstraints,
      newOutputConstraints = toReverse.oldOutputConstraints,
      newProductionLine = toReverse.oldProductionLine,
      newParentOf = toReverse.oldParentOf,
      newChildOf = toReverse.oldChildOf,
      isReversed = true,
      original = toReverse;
}

enum NodeEventType {
  updateGeometry,
  tempGeometry,
  updateIo,
  updateConstraints,
  newProductionLine,
  parentOfUpdate,
  childOfUpdate,
  addedToGraph,
  removedFromGraph;

  NodeEventType get reverse => switch (this) {
    updateGeometry => updateGeometry,
    tempGeometry => tempGeometry,
    updateIo => updateIo,
    updateConstraints => updateConstraints,
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
