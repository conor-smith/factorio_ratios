import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/graph/geometry.dart';
import 'package:factorio_ratios/factorio/production_line.dart';

/*
 * A stateful class can only have it's internal state be meaningfully modified
 * by applying a MutationEvent
 * Said mutationEvents can also be rolled back and redone, completely restoring
 * a previously existing state
 */
abstract mixin class Stateful<T extends MutationEvent> {
  final List<Function(T update)> _listeners = [];

  void addListener(Function(T event) callback) {
    _listeners.add(callback);
  }

  void clearListeners() {
    _listeners.clear();
  }

  void notifyListeners(T update) {
    for (var callback in _listeners) {
      callback(update);
    }
  }

  void apply(T event);
  void redo(T event);
  void rollback(T event);
}

abstract class MutationEvent {
  bool get isReversed;
  MutationEvent get reversed;
}

class EventHistory {
  final int maxSavedEvents;

  // Mutations are only allowed if this is above 0
  // This prevents external objects from making unsafe mutations
  int _mutationLock = 0;

  // Most recent event, and getters to determine if undo or redo is permitted
  int _mostRecentEventIndex = -1;
  bool get canUndo => _mostRecentEventIndex >= 0;
  bool get canRedo => _mostRecentEventIndex < _committedEvents.length - 1;

  // TODO - Should this be a linked list or queue?
  final List<_UpdateEvent> _committedEvents = [];

  // Objects currently undergoing delayedEventOperations
  Set<Stateful> delayedEventOperations = {};

  // Uncommitted events
  Map<BaseGraph, List<GraphEvent>> _uGraphEvents;
  Map<ProdLineNode, List<NodeEvent>> _uNodeEvents;
  Map<DirectedEdge, List<EdgeEvent>> _uEdgeEvents;

  bool get hasUncommittedEvents =>
      _uGraphEvents.isNotEmpty ||
      _uNodeEvents.isNotEmpty ||
      _uEdgeEvents.isNotEmpty;

  // Constructor
  EventHistory(this.maxSavedEvents)
    : _uGraphEvents = {},
      _uNodeEvents = {},
      _uEdgeEvents = {};

  // Listeners should not be updated unless an event is committed,
  // so there's no need to call updateListeners here
  void undoUncommittedEvents() {
    var event = _UpdateEvent(_uGraphEvents, _uNodeEvents, _uEdgeEvents);
    _uGraphEvents = {};
    _uNodeEvents = {};
    _uEdgeEvents = {};

    event.rollback();
  }

  void addGraphEvent(GraphEvent event) => _uGraphEvents.update(
    event.graph,
    (eventsList) => eventsList..add(event),
    ifAbsent: () => [event],
  );

  void addNodeEvent(NodeEvent event) => _uNodeEvents.update(
    event.node,
    (eventsList) => eventsList..add(event),
    ifAbsent: () => [event],
  );

  void addEdgeEvent(EdgeEvent event) => _uEdgeEvents.update(
    event.edge,
    (eventsList) => eventsList..add(event),
    ifAbsent: () => [event],
  );

  void _commit() {
    if (hasUncommittedEvents) {
      var newEvent = _UpdateEvent(_uGraphEvents, _uNodeEvents, _uEdgeEvents);
      _uGraphEvents = {};
      _uNodeEvents = {};
      _uEdgeEvents = {};

      // Check if we have reached our maximum amount of commits
      if (_mostRecentEventIndex == maxSavedEvents - 1) {
        _committedEvents.removeAt(0);
      } else {
        _mostRecentEventIndex++;
      }

      // Drop any events following this new one if required
      if (_committedEvents.length > _mostRecentEventIndex) {
        _committedEvents.removeRange(
          _mostRecentEventIndex,
          _committedEvents.length,
        );
      }

      _committedEvents.add(newEvent);

      newEvent.notifyListeners(false);
    }
  }

  void mutate(Function() function, {bool commit = true}) {
    _mutationLock++;

    try {
      function();
    } catch (e) {
      _mutationLock--;

      if (_mutationLock == 0) {
        undoUncommittedEvents();
      }
      rethrow;
    }

    _mutationLock--;

    if (_mutationLock == 0 && commit) {
      _commit();
    }
  }

  void checkIfMutationPermitted() {
    if (_mutationLock == 0) {
      throw const MutationException('Mutation not currently permitted');
    }
  }
}

class _UpdateEvent {
  final Map<BaseGraph, GraphEvent> graphEvents;
  final Map<ProdLineNode, NodeEvent> nodeEvents;
  final Map<DirectedEdge, EdgeEvent> edgeEvents;

  late final Map<Stateful, MutationEvent> events =
      Map<Stateful, MutationEvent>.from(graphEvents)
        ..addAll(nodeEvents)
        ..addAll(edgeEvents);

  _UpdateEvent(
    Map<BaseGraph, List<GraphEvent>> graphEvents,
    Map<ProdLineNode, List<NodeEvent>> nodeEvents,
    Map<DirectedEdge, List<EdgeEvent>> edgeEvents,
  ) : graphEvents = graphEvents.map(
        (graph, events) => MapEntry(graph, GraphEvent.combine(events)),
      ),
      nodeEvents = nodeEvents.map(
        (node, events) => MapEntry(node, NodeEvent.combine(events)),
      ),
      edgeEvents = edgeEvents.map(
        (edge, events) => MapEntry(edge, EdgeEvent.combine(events)),
      );

  void redo() {
    events.forEach((mutateable, event) {
      mutateable.redo(event);
    });
  }

  void rollback() {
    events.forEach((mutateable, event) {
      mutateable.rollback(event);
    });
  }

  void notifyListeners(bool isRollback) {
    events.forEach(
      (mutable, event) =>
          mutable.notifyListeners(isRollback ? event.reversed : event),
    );
  }
}

class GraphEvent extends MutationEvent {
  final BaseGraph graph;

  final Set<GraphEventType> mutations;

  final GraphGeometry? oldGeometry, newGeometry;
  final Set<ProdLineNode> newNodes, removedNodes;
  final Set<DirectedEdge> newEdges, removedEdges;
  final Set<ItemData> newInputs, newOutputs, removedInputs, removedOutputs;

  final GraphEvent? original;
  @override
  final bool isReversed;
  @override
  late final GraphEvent reversed = original ?? GraphEvent._reverse(this);

  GraphEvent.newNode(BaseGraph graph, ProdLineNode newNode)
    : this._(graph, {GraphEventType.updateNodes}, newNodes: {newNode});

  GraphEvent.removeNode(BaseGraph graph, ProdLineNode removedNode)
    : this._(graph, {GraphEventType.updateNodes}, removedNodes: {removedNode});

  GraphEvent.newEdge(BaseGraph graph, DirectedEdge newEdge)
    : this._(graph, {GraphEventType.updateEdges}, newEdges: {newEdge});

  GraphEvent.removeEdge(BaseGraph graph, DirectedEdge removedEdge)
    : this._(graph, {GraphEventType.updateEdges}, removedEdges: {removedEdge});

  GraphEvent.newInput(BaseGraph graph, ItemData newInput)
    : this._(graph, {GraphEventType.updateInput}, newInputs: {newInput});

  GraphEvent.removeInput(BaseGraph graph, ItemData removedInput)
    : this._(
        graph,
        {GraphEventType.updateInput},
        removedInputs: {removedInput},
      );

  GraphEvent.newOutput(BaseGraph graph, ItemData newOutput)
    : this._(graph, {GraphEventType.updateOutput}, newOutputs: {newOutput});

  GraphEvent.removeOutput(BaseGraph graph, ItemData removedOutput)
    : this._(
        graph,
        {GraphEventType.updateOutput},
        removedOutputs: {removedOutput},
      );

  GraphEvent.updateGeometry(BaseGraph graph, GraphGeometry newGeometry)
    : this._(
        graph,
        {GraphEventType.geometryUpdate},
        oldGeometry: graph.geometry,
        newGeometry: newGeometry,
      );

  GraphEvent.clearGeometry(BaseGraph graph)
    : this._(
        graph,
        {GraphEventType.geometryUpdate},
        oldGeometry: graph.geometry,
        newGeometry: GraphGeometry.uninitialised,
      );

  factory GraphEvent.combine(List<GraphEvent> orderedEvents) {
    Set<GraphEventType> mutations = {};

    Set<ProdLineNode> newNodes = {};
    Set<ProdLineNode> removedNodes = {};
    Set<DirectedEdge> newEdges = {};
    Set<DirectedEdge> removedEdges = {};

    Set<ItemData> newInputs = {};
    Set<ItemData> removedInputs = {};
    Set<ItemData> newOutputs = {};
    Set<ItemData> removedOutputs = {};

    GraphEvent? oldGeometryEvent, newGeometryEvent;
    GraphGeometry? oldGeometry, newGeometry;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case GraphEventType.geometryUpdate:
            oldGeometryEvent ??= event;
            newGeometryEvent = event;

          case GraphEventType.updateNodes:
            newNodes.addAll(event.newNodes);
            removedNodes.addAll(event.removedNodes);

          case GraphEventType.updateEdges:
            newEdges.addAll(event.newEdges);
            removedEdges.addAll(event.removedEdges);

          case GraphEventType.updateInput:
            newInputs.addAll(event.newInputs);
            removedInputs.addAll(event.removedInputs);

          case GraphEventType.updateOutput:
            newOutputs.addAll(event.newOutputs);
            removedOutputs.addAll(event.removedOutputs);
        }
      }
    }

    if (oldGeometryEvent != null) {
      oldGeometry = oldGeometryEvent.oldGeometry;
      newGeometry = newGeometryEvent!.newGeometry;
    }

    _removedWhereBothContain(newNodes, removedNodes);
    _removedWhereBothContain(newEdges, removedEdges);
    _removedWhereBothContain(newInputs, removedInputs);
    _removedWhereBothContain(newOutputs, removedOutputs);

    return GraphEvent._(
      orderedEvents.first.graph,
      mutations,
      removedNodes: removedNodes,
      removedEdges: removedEdges,
      removedInputs: removedInputs,
      removedOutputs: removedOutputs,
      oldGeometry: oldGeometry,
      newNodes: newNodes,
      newEdges: newEdges,
      newInputs: newInputs,
      newOutputs: newOutputs,
      newGeometry: newGeometry,
    );
  }

  GraphEvent._(
    this.graph,
    Set<GraphEventType> mutations, {
    this.oldGeometry,
    Set<ProdLineNode> removedNodes = const {},
    Set<DirectedEdge> removedEdges = const {},
    Set<ItemData> removedInputs = const {},
    Set<ItemData> removedOutputs = const {},
    this.newGeometry,
    Set<ProdLineNode> newNodes = const {},
    Set<DirectedEdge> newEdges = const {},
    Set<ItemData> newInputs = const {},
    Set<ItemData> newOutputs = const {},
  }) : mutations = Set.unmodifiable(mutations),
       removedNodes = Set.unmodifiable(removedNodes),
       removedEdges = Set.unmodifiable(removedEdges),
       removedInputs = Set.unmodifiable(removedInputs),
       removedOutputs = Set.unmodifiable(removedOutputs),
       newNodes = Set.unmodifiable(newNodes),
       newEdges = Set.unmodifiable(newEdges),
       newInputs = Set.unmodifiable(newInputs),
       newOutputs = Set.unmodifiable(newOutputs),
       isReversed = false,
       original = null;

  GraphEvent._reverse(GraphEvent toReverse)
    : graph = toReverse.graph,
      mutations = toReverse.mutations,
      oldGeometry = toReverse.newGeometry,
      removedNodes = toReverse.newNodes,
      removedEdges = toReverse.newEdges,
      removedInputs = toReverse.newInputs,
      removedOutputs = toReverse.newOutputs,
      newGeometry = toReverse.oldGeometry,
      newNodes = toReverse.removedNodes,
      newEdges = toReverse.removedEdges,
      newInputs = toReverse.removedInputs,
      newOutputs = toReverse.removedOutputs,
      isReversed = true,
      original = toReverse;
}

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
        oldProductionLine: node.line,
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

class EdgeEvent extends MutationEvent {
  final DirectedEdge edge;

  final Set<EdgeEventType> mutations;

  final double? oldAmount, newAmount;

  final EdgeGeometry? oldGeometry, newGeometry;

  final EdgeEvent? original;
  @override
  final bool isReversed;
  @override
  late final EdgeEvent reversed = original ?? EdgeEvent._reverse(this);

  EdgeEvent.addToGraph(DirectedEdge edge)
    : this._(edge, {EdgeEventType.addedToGraph});

  EdgeEvent.removeFromGraph(DirectedEdge edge)
    : this._(edge, {EdgeEventType.removedFromGraph});

  EdgeEvent.newAmount(DirectedEdge edge, double newAmount)
    : this._(
        edge,
        {EdgeEventType.newAmount},
        oldAmount: edge.amount,
        newAmount: newAmount,
      );

  EdgeEvent.updateGeometry(DirectedEdge edge, EdgeGeometry newGeometry)
    : this._(
        edge,
        {EdgeEventType.newGeometry},
        oldGeometry: edge.geometry,
        newGeometry: newGeometry,
      );

  EdgeEvent.tempGeometry(DirectedEdge edge, EdgeGeometry tempGeometry)
    : this._(edge, {EdgeEventType.tempGeometry}, newGeometry: tempGeometry);

  EdgeEvent.clearAmount(DirectedEdge edge)
    : this._(edge, {EdgeEventType.newAmount}, oldAmount: edge.amount);

  factory EdgeEvent.combine(List<EdgeEvent> orderedEvents) {
    Set<EdgeEventType> mutations = {};

    EdgeEvent? oldAmountEvent, newAmountEvent;
    double? oldAmount, newAmount;

    EdgeEvent? oldGeometryEvent, newGeometryEvent;
    EdgeGeometry? oldGeometry, newGeometry;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case EdgeEventType.newAmount:
            oldAmountEvent ??= event;
            newAmountEvent = event;

          case EdgeEventType.newGeometry:
            oldGeometryEvent ??= event;
            newGeometryEvent = event;

          case EdgeEventType.addedToGraph:
          case EdgeEventType.removedFromGraph:
            break;

          case EdgeEventType.tempGeometry:
            throw const GraphException(
              'Cannot combine edge temp geometry event',
            );
        }
      }
    }

    if (mutations.containsAll(EdgeEventType.creationEvents)) {
      mutations.removeAll(EdgeEventType.creationEvents);
    }

    if (oldAmountEvent != null) {
      oldAmount = oldAmountEvent.oldAmount;
      newAmount = newAmountEvent!.newAmount;
    }

    if (oldGeometryEvent != null) {
      oldGeometry = oldGeometryEvent.oldGeometry;
      newGeometry = newGeometryEvent!.newGeometry;
    }

    return EdgeEvent._(
      orderedEvents.first.edge,
      mutations,
      oldAmount: oldAmount,
      oldGeometry: oldGeometry,
      newAmount: newAmount,
      newGeometry: newGeometry,
    );
  }

  EdgeEvent._(
    this.edge,
    Set<EdgeEventType> mutations, {
    this.oldAmount,
    this.oldGeometry,
    this.newAmount,
    this.newGeometry,
  }) : mutations = Set.unmodifiable(mutations),
       isReversed = false,
       original = null;

  EdgeEvent._reverse(EdgeEvent toReverse)
    : edge = toReverse.edge,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldAmount = toReverse.newAmount,
      oldGeometry = toReverse.newGeometry,
      newAmount = toReverse.oldAmount,
      newGeometry = toReverse.oldGeometry,
      isReversed = true,
      original = toReverse;
}

enum GraphEventType {
  geometryUpdate,
  updateNodes,
  updateEdges,
  updateInput,
  updateOutput,
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

enum EdgeEventType {
  newAmount,
  newGeometry,
  tempGeometry,
  addedToGraph,
  removedFromGraph;

  EdgeEventType get reverse => switch (this) {
    newAmount => newAmount,
    newGeometry => newGeometry,
    tempGeometry => tempGeometry,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<EdgeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}

class MutationException implements Exception {
  final String message;

  const MutationException(this.message);

  @override
  String toString() => 'MutationException: $message';
}

void _removedWhereBothContain(Set set1, Set set2) {
  for (var item in List.from(set1)) {
    if (set2.contains(item)) {
      set1.remove(item);
      set2.remove(item);
    }
  }
}
