part of '../graph.dart';

// Only one of these may exist per graph tree
class _EventHistory {
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

  // Uncommitted events
  Map<BaseGraph, List<GraphEvent>> _uGraphEvents;
  Map<ProdLineNode, List<NodeEvent>> _uNodeEvents;
  Map<DirectedEdge, List<EdgeEvent>> _uEdgeEvents;

  bool get hasUncommittedEvents =>
      _uGraphEvents.isNotEmpty ||
      _uNodeEvents.isNotEmpty ||
      _uEdgeEvents.isNotEmpty;

  // Constructor
  _EventHistory(this.maxSavedEvents)
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
    if (!hasUncommittedEvents) {
      var newEvent = _UpdateEvent(
        _uGraphEvents
          ..updateAll((graph, events) => [GraphEvent.combine(events)]),
        _uNodeEvents..updateAll((node, events) => [NodeEvent.combine(events)]),
        _uEdgeEvents..updateAll((edge, events) => [EdgeEvent.combine(events)]),
      );
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
  final Map<BaseGraph, List<GraphEvent>> graphEvents;
  final Map<ProdLineNode, List<NodeEvent>> nodeEvents;
  final Map<DirectedEdge, List<EdgeEvent>> edgeEvents;

  late final Map<Mutateable, List<MutationEvent>> events =
      Map<Mutateable, List<MutationEvent>>.from(graphEvents)
        ..addAll(nodeEvents)
        ..addAll(edgeEvents);

  _UpdateEvent(this.graphEvents, this.nodeEvents, this.edgeEvents);

  void redo() {
    events.forEach((mutateable, events) {
      for (var event in events) {
        mutateable.redo(event);
      }
    });
  }

  void rollback() {
    events.forEach((mutateable, events) {
      for (var event in events.reversed) {
        mutateable.rollback(event);
      }
    });
  }

  void notifyListeners(bool isRollback) {
    events.forEach(
      (mutateable, events) => mutateable.notifyListeners(isRollback, events),
    );
  }
}
