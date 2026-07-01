part of 'base_planner.dart';

/// Represents a snapshot of all states of elements in [BasePlanner].
class Snapshot {
  final Map<BasePlannerElement, dynamic> states;

  Snapshot._(Map<BasePlannerElement, dynamic> states)
    : states = Map.unmodifiable(states);
}

/// Builds a snapshot in 3 stages.
///
/// ### Spec update
/// Users can add and remove elements, update geometry, etc.
/// They can also set and update internal constraints on relevant nodes.
/// However, no updates to item flow (ioData, edge amounts, etc) may
/// take place during this time
///
/// ### Snapshot building
/// This occurs once [build] is called. At this point, the user is locked out
/// from making any more changes. It is because of this that we can now safely
/// calculate node itemIo and edge amounts. New edges and nodes will be created
/// to satisfy any unfulfilled IO of any node. It is only during this step that
/// cyclical dependencies will be checked for. Despite this, ioData will not yet
/// be calculated, as some itemIo data will need to be redone multiple times,
/// and it's best to avoid unnecessary work.
///
/// ### Element building
/// It is here that all the [BasePlannerElement.state] items will be built.
/// Final validation will occur as well. Once complete, a new snapshot will
/// be added to the [BasePlanner].
class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<BasePlannerElement, Builder> _updatedElements = {};
  final Set<BasePlannerElement> _removedElements = {};

  bool _isBuilding = false;

  bool _updateIo = false;
  Set<Graph> _graphsToUpdateLayout = {};

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

  void addToSnapshot(BasePlannerElement element, Builder builder) =>
      _updatedElements[element] = builder;

  void removeFromSnapshot(BasePlannerElement element) {
    _removedElements.add(element);
  }

  void queueIoUpdate() => _updateIo = true;

  void queueLayoutUpdate(Graph graph) => _graphsToUpdateLayout.add(graph);

  @override
  Snapshot build() {
    _isBuilding = true;

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
}
