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
  final Set<ProdLineNode> _nodesToUpdateEdges = {};

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

  /// Only at the final stage of building the snapshot will io calculations take place.
  /// This will queue up any nodes with io to be updated, as well as call
  /// [queueNodeUpdateEdges] on that node.
  void queueNodeIoUpdate(ProdLineNode node) {
    _nodesToUpdateIo.add(node);
    _nodesToUpdateEdges.add(node);
  }

  /// The amount values in edges are set according to the parent / child node io.
  /// Adding a node here indicates that attached edges must be updated
  void queueNodeUpdateEdges(ProdLineNode node) {
    _nodesToUpdateEdges.add(node);
  }

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

    graphToSolve.getStateBuilder().clearIo();
    solvedGraphs.add(graphToSolve);
  }
}
