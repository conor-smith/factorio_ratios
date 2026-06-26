part of 'base_planner.dart';

/// Represents a snapshot of all states of elements in [BasePlanner].
class Snapshot {
  final Map<BasePlannerElement, dynamic> states;

  Snapshot._(Map<BasePlannerElement, dynamic> states)
    : states = Map.unmodifiable(states);
}

class SnapshotBuilder extends Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<BasePlannerElement, Builder<dynamic>> _updatedElements = {};
  final Set<BasePlannerElement> _removedElements = {};

  final Set<Graph> _graphsToUpdateIo = {};
  final Set<ProdLineNode> _nodesToUpdateIo = {};

  bool _isBuilding = false;

  bool get hasChanges =>
      _updatedElements.isNotEmpty || _removedElements.isNotEmpty;

  SnapshotBuilder._from(this._previousSnapshot);

  void throwIfNotBuilding() {
    if (!_isBuilding) {
      throw const BasePlannerException(
        'SnapshotBuilder is not currently building',
      );
    }
  }

  void addToSnapsnot<
    E extends BasePlannerElement<St, dynamic>,
    St,
    B extends Builder<St>
  >(E element, B builder) => _updatedElements[element] = builder;

  void removeFromSnapshot(BasePlannerElement element) {
    _removedElements.add(element);
  }

  void queueGraphIoUpdate(Graph graph) {
    while (!_graphsToUpdateIo.contains(graph)) {
      _graphsToUpdateIo.add(graph);
      graph = graph.parentGraph;

      if (graph.isRoot) {
        break;
      }
    }
  }

  void queueNodeIoUpdate(ProdLineNode node) => _nodesToUpdateIo.add(node);

  @override
  Snapshot build() {
    _isBuilding = true;

    Set<Graph> solvedGraphs = {};
    for (var graphToSolve in _graphsToUpdateIo) {
      _recursivelyUpdateChildGraphs(graphToSolve, solvedGraphs);
    }

    Map<BasePlannerElement, dynamic> newStateMap = Map.from(
      _previousSnapshot.states,
    );

    for (var removedElement in _removedElements) {
      removedElement.cancelStateBuilder();
      _updatedElements.remove(removedElement);
      newStateMap.remove(removedElement);
    }

    var updatedStates = _updatedElements.map(
      (element, builder) => MapEntry(element, builder.build()),
    );
    newStateMap.addAll(updatedStates);

    return Snapshot._(newStateMap);
  }

  void _recursivelyUpdateChildGraphs(
    Graph graphToSolve,
    Set<Graph> solvedGraphs,
  ) {
    if (solvedGraphs.contains(graphToSolve)) {
      return;
    }

    for (var graphNodeToSolve in _graphsToUpdateIo.union(
      graphToSolve.graphNodes,
    )) {
      _recursivelyUpdateChildGraphs(graphNodeToSolve, solvedGraphs);
    }

    graphToSolve.getStateBuilder().calculateIo();
    solvedGraphs.add(graphToSolve);
  }
}
