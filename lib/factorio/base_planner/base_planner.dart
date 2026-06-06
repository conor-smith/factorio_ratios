import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/json/json.dart';

class BasePlanner implements ToJson, EventNotifier<BasePlannerEvent> {
  static const maxSnapshots = 20;

  final FactorioDatabase db;

  final EventNotifier<BasePlannerEvent> _notifier = EventNotifier();

  final List<BasePlannerSnapshot> _snapshots = [
    const BasePlannerSnapshot._empty(),
  ];
  late final List<BasePlannerSnapshot> snapshots = UnmodifiableListView(
    _snapshots,
  );
  int _snapshotIndex = 0;
  int get snapshotIndex => _snapshotIndex;
  _BasePlannerSnapshotBuilder? _snapshotBuilder;

  int _mutationLock = 0;

  BasePlanner(this.db);

  @override
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(BasePlannerEvent event) callback) =>
      _notifier.eventCallback = callback;
  @override
  void clearCallback() => _notifier.clearCallback();
  @override
  void notifyListener(BasePlannerEvent event) =>
      _notifier.notifyListener(event);

  void throwIfMutationNotPermitted() {
    if (_mutationLock == 0) {
      throw const BasePlannerException(
        'State mutation not currently permitted',
      );
    }
  }

  void setCurrentShapshot(int snapshotIndex) {
    if (snapshotIndex < 0 || snapshotIndex >= _snapshots.length) {
      throw BasePlannerException(
        'Snapshot index $snapshotIndex is out of bounds',
      );
    }

    if (snapshotIndex != _snapshotIndex) {
      var currentSnapshot = _snapshots[_snapshotIndex];
      var nextSnapshot = _snapshots[snapshotIndex];

      nextSnapshot.applyAllStates();
      nextSnapshot.notifyRequiredListeners(this, currentSnapshot);

      _snapshotIndex = snapshotIndex;
    }
  }

  void initialiseGraph(Graph newGraph) =>
      _snapshotBuilderOrThrow().addGraph(newGraph);
  GraphStateBuilder getGraphStateBuilder(Graph graph) =>
      _snapshotBuilderOrThrow().getGraphStateBuilder(graph);
  void removeGraph(Graph graph) => _snapshotBuilderOrThrow().removeGraph(graph);

  void initialiseNode(Node newNode) =>
      _snapshotBuilderOrThrow().addNode(newNode);
  NodeStateBuilder getNodeStateBuilder(Node node) =>
      _snapshotBuilderOrThrow().getNodeStateBuilder(node);
  void removeNode(Node node) => _snapshotBuilderOrThrow().removeNode(node);

  void initialiseEdge(Edge newEdge) =>
      _snapshotBuilderOrThrow().addEdge(newEdge);
  EdgeStateBuilder getEdgeStateBuilder(Edge edge) =>
      _snapshotBuilderOrThrow().getEdgeStateBuilder(edge);
  void removeEdge(Edge edge) => _snapshotBuilderOrThrow().removeEdge(edge);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  void _buildNextSnapshot(Function function) {
    var firstCall = _mutationLock == 0;
    try {
      if (firstCall) {
        _snapshotBuilder = _BasePlannerSnapshotBuilder.from(
          _snapshots[_snapshotIndex],
        );
      }

      _mutationLock++;
      function();

      if (firstCall) {
        var newSnapshot = _snapshotBuilder!.buildAndNotifyListeners(this);
        _snapshotBuilder = null;

        if (_snapshotIndex == maxSnapshots - 1) {
          _snapshots.removeAt(0);
        } else {
          _snapshotIndex++;
          _snapshots.removeRange(_snapshotIndex, _snapshots.length);
        }
        _snapshots.add(newSnapshot);
      }

      _mutationLock--;
    } catch (e) {
      _mutationLock--;

      if (firstCall) {
        _snapshots[_snapshotIndex].applyAllStates();
        throw BasePlannerException('Encountered exception during mutation', e);
      } else {
        rethrow;
      }
    }
  }

  _BasePlannerSnapshotBuilder _snapshotBuilderOrThrow() {
    var builder = _snapshotBuilder;

    if (builder == null) {
      throw const BasePlannerException(
        'State mutations are not permitted at this time',
      );
    } else {
      return builder;
    }
  }
}

class BasePlannerEvent {
  final List<Graph> addedGraphs;
  final List<Graph> removedGraphs;

  BasePlannerEvent._newSnapshot({
    required this.addedGraphs,
    required this.removedGraphs,
  });
}

class BasePlannerSnapshot {
  final Map<Graph, GraphState> graphStates;
  final Map<Node, NodeState> nodeStates;
  final Map<Edge, EdgeState> edgeStates;

  const BasePlannerSnapshot._empty()
    : graphStates = const {},
      nodeStates = const {},
      edgeStates = const {};

  BasePlannerSnapshot._(
    Map<Graph, GraphState> graphStates,
    Map<Node, NodeState> nodeStates,
    Map<Edge, EdgeState> edgeStates,
  ) : graphStates = Map.unmodifiable(graphStates),
      nodeStates = Map.unmodifiable(nodeStates),
      edgeStates = Map.unmodifiable(edgeStates);

  void applyAllStates() {
    _applyStatesForType(graphStates);
    _applyStatesForType(nodeStates);
    _applyStatesForType(edgeStates);
  }

  void notifyRequiredListeners(
    BasePlanner basePlanner,
    BasePlannerSnapshot oldSnapshot,
  ) {
    _notifyRequiredListenersForType(oldSnapshot.graphStates, graphStates);
    _notifyRequiredListenersForType(oldSnapshot.nodeStates, nodeStates);
    _notifyRequiredListenersForType(oldSnapshot.edgeStates, edgeStates);

    var oldGraphs = oldSnapshot.graphStates.keys.toSet();
    var newGraphs = graphStates.keys.toSet();

    basePlanner.notifyListener(
      BasePlannerEvent._newSnapshot(
        addedGraphs: oldGraphs.difference(newGraphs).toList(),
        removedGraphs: newGraphs.difference(oldGraphs).toList(),
      ),
    );
  }

  void _applyStatesForType<
    B extends BasePlannerElement<St, dynamic>,
    St extends ElementState
  >(Map<B, St> elementState) =>
      elementState.forEach((element, state) => element.state = state);

  void _notifyRequiredListenersForType<
    B extends BasePlannerElement<St, dynamic>,
    St extends ElementState
  >(Map<B, St> oldStates, Map<B, St> newStates) =>
      newStates.forEach((element, newState) {
        var oldState = oldStates[element];

        if (oldState != null && oldState != newState) {
          element.notifyListenerOfStateChange(oldState, newState);
        }
      });
}

class BasePlannerException extends FactorioException {
  const BasePlannerException(super.message, [super.cause]);
}

class _BasePlannerSnapshotBuilder {
  BasePlannerSnapshot previousSnapshot;

  _GraphUpdateTracker graphUpdates = _GraphUpdateTracker();
  _NodeUpdateTracker nodeUpdates = _NodeUpdateTracker();
  _EdgeUpdateTracker edgeUpdates = _EdgeUpdateTracker();

  _BasePlannerSnapshotBuilder.from(this.previousSnapshot);

  void addGraph(Graph newGraph) => graphUpdates.addElement(newGraph);
  void addNode(Node newNode) => nodeUpdates.addElement(newNode);
  void addEdge(Edge newEdge) => edgeUpdates.addElement(newEdge);

  GraphStateBuilder getGraphStateBuilder(Graph graph) =>
      graphUpdates.getStateBuilder(graph);
  NodeStateBuilder getNodeStateBuilder(Node node) =>
      nodeUpdates.getStateBuilder(node);
  EdgeStateBuilder getEdgeStateBuilder(Edge edge) =>
      edgeUpdates.getStateBuilder(edge);

  void removeGraph(Graph graph) => graphUpdates.removeElement(graph);
  void removeNode(Node node) => nodeUpdates.removeElement(node);
  void removeEdge(Edge edge) => edgeUpdates.removeElement(edge);

  BasePlannerSnapshot buildAndNotifyListeners(BasePlanner basePlanner) {
    var graphStates = graphUpdates.applyStateAndUpdateListeners();
    var nodeStates = nodeUpdates.applyStateAndUpdateListeners();
    var edgeStates = edgeUpdates.applyStateAndUpdateListeners();

    basePlanner.notifyListener(
      BasePlannerEvent._newSnapshot(
        addedGraphs: graphUpdates.newElements.keys.toList(),
        removedGraphs: graphUpdates.removedElements.toList(),
      ),
    );

    return BasePlannerSnapshot._(graphStates, nodeStates, edgeStates);
  }
}

class _UpdateTracker<
  E extends BasePlannerElement<St, dynamic>,
  St extends ElementState,
  B extends Builder<St>
> {
  final B Function(E element) createBuilderAndSetState;

  final Map<E, B> newElements = {};
  final Map<E, _StateAndBuilder<St, B>> updatedElements = {};
  final Set<E> removedElements = {};

  _UpdateTracker(this.createBuilderAndSetState);

  void addElement(E element) =>
      newElements[element] = createBuilderAndSetState(element);

  B getStateBuilder(E element) =>
      newElements[element] ??
      updatedElements
          .putIfAbsent(
            element,
            () => _StateAndBuilder(
              element.state,
              createBuilderAndSetState(element),
            ),
          )
          .builder;

  void removeElement(E element) => removedElements.add(element);

  Map<E, St> applyStateAndUpdateListeners() {
    Map<E, St> toReturn = {};

    newElements.forEach((element, builder) {
      var newState = builder.build();
      element.state = newState;
      toReturn[element] = newState;
    });

    updatedElements.forEach((element, stateAndBuilder) {
      var newState = stateAndBuilder.builder.build();
      element.state = newState;
      toReturn[element] = newState;

      if (!removedElements.contains(element)) {
        element.notifyListenerOfStateChange(
          stateAndBuilder.state,
          element.state,
        );
      }
    });

    return toReturn;
  }
}

class _GraphUpdateTracker
    extends _UpdateTracker<Graph, GraphState, GraphStateBuilder> {
  _GraphUpdateTracker()
    : super((graph) {
        var builder = GraphStateBuilder.from(graph.state);
        graph.state = builder;
        return builder;
      });
}

class _NodeUpdateTracker
    extends _UpdateTracker<Node, NodeState, NodeStateBuilder> {
  _NodeUpdateTracker()
    : super((node) {
        var builder = NodeStateBuilder.from(node.state);
        node.state = builder;
        return builder;
      });
}

class _EdgeUpdateTracker
    extends _UpdateTracker<Edge, EdgeState, EdgeStateBuilder> {
  _EdgeUpdateTracker()
    : super((edge) {
        var builder = EdgeStateBuilder.from(edge.state);
        edge.state = builder;
        return builder;
      });
}

class _StateAndBuilder<St, B> {
  final St state;
  final B builder;

  _StateAndBuilder(this.state, this.builder);
}
