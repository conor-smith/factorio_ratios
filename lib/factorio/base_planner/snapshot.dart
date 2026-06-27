part of 'base_planner.dart';

/// Represents a snapshot of all states of elements in [BasePlanner].
class Snapshot {
  final Map<BasePlannerElement, dynamic> states;

  Snapshot._(Map<BasePlannerElement, dynamic> states)
    : states = Map.unmodifiable(states);
}

class SnapshotBuilder implements Builder<Snapshot> {
  final BasePlanner _basePlanner;

  final Snapshot _previousSnapshot;

  final Map<BasePlannerElement, Builder<dynamic>> _updatedElements = {};
  final Set<BasePlannerElement> _removedElements = {};

  final Set<ProdLineNode> _nodesToUpdateIo = {};

  bool _isBuilding = false;

  bool get hasChanges =>
      _updatedElements.isNotEmpty || _removedElements.isNotEmpty;

  SnapshotBuilder._from(this._basePlanner, this._previousSnapshot);

  void throwIfNotBuilding() {
    if (!_isBuilding) {
      throw const BasePlannerException(
        'SnapshotBuilder is not currently building',
      );
    }
  }

  void addToSnapshot<
    E extends BasePlannerElement<St, dynamic>,
    St,
    B extends Builder<St>
  >(E element, B builder) => _updatedElements[element] = builder;

  void removeFromSnapshot(BasePlannerElement element) {
    _removedElements.add(element);
  }

  /// Only at the final stage of building the snapshot will io calculations take place.
  /// This will add [node] to a set which will be calculated when the snapshot is built.
  void queueNodeIoUpdate(ProdLineNode node) {
    _nodesToUpdateIo.add(node);
  }

  @override
  Snapshot build() {
    _isBuilding = true;

    _nodesToUpdateIo.removeAll(_removedElements);

    _basePlanner.rootGraph.determineIoOfAllNodes(_nodesToUpdateIo);

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
