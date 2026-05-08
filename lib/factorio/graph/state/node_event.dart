part of 'state.dart';

class NodeEvent extends MutationEvent {
  final ProdLineNode node;

  final Set<NodeEventType> mutations;

  final ProductionLineIo? oldIo, newIo;
  final NodeGeometry? oldGeometry, newGeometry;
  final ProductionLine? oldProductionLine, newProductionLine;
  final List<DirectedEdge>? oldParents, oldChildren, newParents, newChildren;
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
          NodeEventType.childrenUpdate,
          NodeEventType.parentsUpdate,
        },
        oldChildren: node.children,
        oldParents: node.parents,
        newChildren: const [],
        newParents: const [],
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
        const {NodeEventType.childrenUpdate},
        oldChildren: node.children,
        newChildren: [...node.children, newChildEdge],
      );

  NodeEvent.newParentEdge(ProdLineNode node, DirectedEdge newParentEdge)
    : this._(
        node,
        const {NodeEventType.parentsUpdate},
        oldParents: node.parents,
        newParents: [...node.parents, newParentEdge],
      );

  NodeEvent.removeChildEdge(ProdLineNode node, DirectedEdge removedChildEdge)
    : this._(
        node,
        const {NodeEventType.childrenUpdate},
        oldChildren: node.children,
        newChildren: List.from(node.children)..remove(removedChildEdge),
      );

  NodeEvent.removeParentEdge(ProdLineNode node, DirectedEdge removedParentEdge)
    : this._(
        node,
        const {NodeEventType.parentsUpdate},
        oldParents: node.parents,
        newParents: List.from(node.parents)..remove(removedParentEdge),
      );

  NodeEvent.tempGeometry(ProdLineNode node, NodeGeometry tempData)
    : this._(node, const {NodeEventType.tempGeometry}, newGeometry: tempData);

  factory NodeEvent.combine(List<NodeEvent> orderedEvents) {
    Set<NodeEventType> mutations = {};

    NodeEvent? oldGeometryEvent, newGeometryEvent;
    NodeEvent? oldIoEvent, newIoEvent;
    NodeEvent? oldConstraintsEvent, newConstraintsEvent;
    NodeEvent? oldProdLineEvent, newProdLineEvent;
    NodeEvent? oldChildrenEvent, newChildrenEvent;
    NodeEvent? oldParentsEvent, newParentsEvent;

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

          case NodeEventType.childrenUpdate:
            oldChildrenEvent ??= event;
            newChildrenEvent = event;

          case NodeEventType.parentsUpdate:
            oldParentsEvent ??= event;
            newParentsEvent = event;

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
      oldChildren: oldChildrenEvent?.oldChildren,
      oldParents: oldParentsEvent?.oldParents,
      newGeometry: newGeometryEvent?.newGeometry,
      newIo: newIoEvent?.newIo,
      newProductionLine: newProdLineEvent?.newProductionLine,
      newInputConstraints: newConstraintsEvent?.newInputConstraints,
      newOutputConstraints: newConstraintsEvent?.newOutputConstraints,
      newChildren: newChildrenEvent?.newChildren,
      newParents: newParentsEvent?.newParents,
    );
  }

  NodeEvent._(
    this.node,
    Set<NodeEventType> mutations, {
    this.oldIo,
    this.oldProductionLine,
    this.oldInputConstraints,
    this.oldOutputConstraints,
    this.oldParents,
    this.oldChildren,
    this.oldGeometry,
    this.newProductionLine,
    this.newIo,
    ItemIo? newInputConstraints,
    ItemIo? newOutputConstraints,
    Iterable<DirectedEdge>? newChildren,
    Iterable<DirectedEdge>? newParents,
    this.newGeometry,
  }) : mutations = Set.unmodifiable(mutations),
       newInputConstraints = _unmodifiableOrNullMap(newInputConstraints),
       newOutputConstraints = _unmodifiableOrNullMap(newOutputConstraints),
       newChildren = _unmodifiableOrNullList(newChildren),
       newParents = _unmodifiableOrNullList(newParents),
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
      oldChildren = toReverse.newChildren,
      oldParents = toReverse.newParents,
      newIo = toReverse.oldIo,
      newGeometry = toReverse.oldGeometry,
      newInputConstraints = toReverse.oldInputConstraints,
      newOutputConstraints = toReverse.oldOutputConstraints,
      newProductionLine = toReverse.oldProductionLine,
      newChildren = toReverse.oldChildren,
      newParents = toReverse.oldParents,
      isReversed = true,
      original = toReverse;
}

enum NodeEventType {
  updateGeometry,
  tempGeometry,
  updateIo,
  updateConstraints,
  newProductionLine,
  childrenUpdate,
  parentsUpdate,
  addedToGraph,
  removedFromGraph;

  NodeEventType get reverse => switch (this) {
    updateGeometry => updateGeometry,
    tempGeometry => tempGeometry,
    updateIo => updateIo,
    updateConstraints => updateConstraints,
    newProductionLine => newProductionLine,
    childrenUpdate => childrenUpdate,
    parentsUpdate => parentsUpdate,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<NodeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}
