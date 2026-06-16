import 'dart:collection';
import 'dart:math';

import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/json/json.dart';

part 'interfaces.dart';
part 'event_notifier_impl.dart';

/// The single source of truth for the application.
///
/// Ultimately represents a tree. Each [Graph] can have an arbitrary amount of
/// [Graph.graphNodes], and each graph node can have only one parent.
/// The only [Graph] with no value for [Graph.parentGraph] is the [rootGraph].
///
/// State changes can only be made within [buildNextSnapshot].
/// Any attempts to call [BasePlannerElement.getStateBuilder] outside of this
/// method will throw an exception.
/// Once the function passed to [buildNextSnapshot] is complete, a new
/// [Snapshot] will be created and added to [snapshots].
/// Snapshots can be navigated via [goToSnapshot], at which point, the state of
/// all objects will be reset to the state they were in during that snapshot.
///
/// [snapshots] cannot be longer than [maxSnapshots]. If a new snapshot is added
/// after it reaches this length, the first snapshot will be removed, and all
/// elements will be moved back 1.
/// Alternatively, if the user navigates to a previous snapshot and builds a new
/// one from there, all subsequent snapshots will be deleted.
///
/// [activeGraph] represents the current [Graph] to be displayed.
/// Everytime [activeGraph] is updated, [selectedNodes] will be cleared.
class BasePlanner implements ToJson, EventNotifier<BasePlannerEvent> {
  static const maxSnapshots = 20;

  final FactorioDatabase db;

  late final Graph rootGraph;
  final List<InGameMachine> sortedMachines;
  final Map<Surface, SurfaceProperties> surfaceProperties;

  Graph get activeGraph => _activeGraph;
  late final Set<NodeElement> selectedNodes = UnmodifiableSetView(
    _selectedNodes,
  );

  late Graph _activeGraph;
  final Set<NodeElement> _selectedNodes = {};

  final EventNotifier<BasePlannerEvent> _notifier = EventNotifierImpl();

  final List<Snapshot> _snapshots = [];
  late final List<Snapshot> snapshots = UnmodifiableListView(_snapshots);
  int _snapshotIndex = 0;
  int get snapshotIndex => _snapshotIndex;
  SnapshotBuilder? _snapshotBuilder;

  int _mutationLock = 0;

  BasePlanner(this.db)
    : surfaceProperties = db.surfaceMap.map(
        (name, surface) => MapEntry(
          surface,
          SurfaceProperties._(
            defaultRecipes: surface.recipes.where(
              (recipe) => recipe.isSimple && recipe.craftingMachines.isNotEmpty,
            ),
            resources: surface.resourceItems.map((item) => InGameItem(item)),
            availableSolidFuels: surface.resourceItems
                .whereType<SolidItem>()
                .where((solidItem) => (solidItem.fuelValue ?? 0) > 0)
                .map((solidItem) => InGameSolidItem(solidItem)),
          ),
        ),
      ),
      sortedMachines = List.unmodifiable(
        db.craftingMachineMap.values
            .map((machine) => InGameMachine(machine))
            .toList()
          ..sort(
            (machine1, machine2) =>
                machine2.craftingSpeed.compareTo(machine1.craftingSpeed),
          ),
      ) {
    // Create first snapshot and root graph
    rootGraph = Graph.rootGraph(this, db.surfaceMap['nauvis']);
    _snapshots.add(Snapshot._({rootGraph: rootGraph.state}));
  }

  @override
  void addListener(
    Object listener,
    Function(BasePlannerEvent event) callback,
  ) => _notifier.addListener(listener, callback);
  @override
  void removeListener(Object listener) => _notifier.removeListener(listener);
  @override
  void clearListeners() => _notifier.clearListeners();
  @override
  void notifyListeners(BasePlannerEvent event) =>
      _notifier.notifyListeners(event);

  void throwIfMutationNotPermitted() {
    if (_mutationLock == 0) {
      throw const BasePlannerException(
        'State mutation not currently permitted',
      );
    }
  }

  void goToSnapshot(int snapshotIndex) {
    if (snapshotIndex < 0 || snapshotIndex >= _snapshots.length) {
      throw BasePlannerException(
        'Snapshot index $snapshotIndex is out of bounds',
      );
    }
  }

  void buildNextSnapshot(Function function) {
    var firstCall = _mutationLock == 0;
    try {
      if (firstCall) {
        _snapshotBuilder = SnapshotBuilder._from(_snapshots[_snapshotIndex]);
      }

      _mutationLock++;
      function();
      _mutationLock--;

      if (firstCall && _snapshotBuilder!.hasChanges) {
        var oldSnapshot = _snapshots[_snapshotIndex];
        var newSnapshot = _snapshotBuilder!.build();
        _snapshotBuilder = null;

        if (_snapshotIndex == maxSnapshots - 1) {
          _snapshots.removeAt(0);
        } else {
          _snapshotIndex++;
          _snapshots.removeRange(_snapshotIndex, _snapshots.length);
        }
        _snapshots.add(newSnapshot);

        _applySnapshotAndUpdateListeners(oldSnapshot, newSnapshot);
      } else if (firstCall && !_snapshotBuilder!.hasChanges) {
        _snapshotBuilder = null;
      }
    } catch (e) {
      _mutationLock--;
      if (firstCall) {
        _applySnapshot(_snapshots[_snapshotIndex]);
        throw BasePlannerException('Encountered exception during mutation', e);
      } else {
        rethrow;
      }
    }
  }

  SnapshotBuilder getSnapshotBuilder() {
    if (_snapshotBuilder == null) {
      throw const BasePlannerException('No snapshot currently being built');
    }

    return _snapshotBuilder!;
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  void _applySnapshotAndUpdateListeners(
    Snapshot oldSnapshot,
    Snapshot newSnapshot,
  ) {
    _mutationLock++;
    for (var element in oldSnapshot.states.keys) {
      if (!newSnapshot.states.containsKey(element)) {
        // Clear listeners on removed items
        element.clearListeners();
      }
    }

    newSnapshot.states.forEach((element, newState) {
      element.state = newState;
    });
    _mutationLock--;
  }

  void _applySnapshot(Snapshot snapshot) {
    _mutationLock++;
    snapshot.states.forEach((element, newState) => element.state = newState);
    _mutationLock--;
  }
}

class BasePlannerEvent {
  // TODO
}

class Snapshot {
  final Map<BasePlannerElement, dynamic> states;

  Snapshot._(Map<BasePlannerElement, dynamic> states)
    : states = Map.unmodifiable(states);
}

class SnapshotBuilder extends Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<BasePlannerElement, Builder<dynamic>> _updatedElements = {};
  final Set<BasePlannerElement> _removedElements = {};

  bool get hasChanges =>
      _updatedElements.isNotEmpty || _removedElements.isNotEmpty;

  SnapshotBuilder._from(this._previousSnapshot);

  void addToSnapsnot<
    E extends BasePlannerElement<St, dynamic>,
    St,
    B extends Builder<St>
  >(E element, B builder) => _updatedElements[element] = builder;

  void removeFromSnapshot(BasePlannerElement element) =>
      _removedElements.add(element);

  @override
  Snapshot build() {
    for (var removedElement in _removedElements) {
      removedElement.cancelStateBuilder();
      _updatedElements.remove(removedElement);
    }

    var updatedStates = _updatedElements.map(
      (element, builder) => MapEntry(element, builder.build()),
    );
    Map<BasePlannerElement, dynamic> newStateMap = Map.from(
      _previousSnapshot.states,
    );
    newStateMap.addAll(updatedStates);

    return Snapshot._(newStateMap);
  }
}

class SurfaceProperties {
  static const empty = SurfaceProperties._empty();

  final List<Recipe> defaultRecipes;
  final List<InGameItem> resources;
  final List<InGameSolidItem> availableSolidFuels;
  // TODO - Liquid fuels

  SurfaceProperties._({
    required Iterable<Recipe> defaultRecipes,
    required Iterable<InGameItem> resources,
    required Iterable<InGameSolidItem> availableSolidFuels,
  }) : defaultRecipes = List.unmodifiable(defaultRecipes),
       resources = List.unmodifiable(resources),
       availableSolidFuels = List.unmodifiable(availableSolidFuels);

  const SurfaceProperties._empty()
    : defaultRecipes = const [],
      resources = const [],
      availableSolidFuels = const [];
}

class BasePlannerException extends FactorioException {
  const BasePlannerException(super.message, [super.cause]);
}
