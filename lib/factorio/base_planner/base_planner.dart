import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/change_tracker/change_trackers.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/json/json.dart';
import 'package:factorio_ratios/utility/builder.dart';

part 'base_planner_element.dart';
part 'event_notifier.dart';

/// The single source of truth for the application.
///
/// Ultimately represents a tree. Each [Graph] can have an arbitrary amount of
/// [Graph.graphNodes], and each graph node can have only one parent.
/// The root of the tree is represented by the [rootGraph] where [Graph.parentGraph]
/// is itself.
///
/// State changes can only be made within [buildNextSnapshot].
/// Any attempts to call [BasePlannerElement.getChangeTracker] outside of this
/// method will throw an exception.
/// Once the function passed to [buildNextSnapshot] is complete, a new
/// [Snapshot] will be created and added to [snapshots].
/// Snapshots can be navigated via [goToSnapshot], at which point, the state of
/// all objects will be reset to the state they were in during that snapshot.
///
/// The [snapshots] list cannot be longer than [maxSnapshots].
/// If a new snapshot is added after it reaches this length,
/// the first snapshot in the list will be removed.
/// Alternatively, if the user navigates to a previous snapshot and builds a new
/// one from there, all subsequent snapshots will be deleted.
///
/// [activeGraph] represents the current [Graph] to be displayed.
/// Everytime [activeGraph] is updated, [selectedElements] will be cleared.
class BasePlanner
    with EventNotifier<BasePlannerEvent>
    implements ToJson, EventNotifier<BasePlannerEvent> {
  static const maxSnapshots = 20;

  final FactorioDatabase db;
  late final Graph rootGraph;

  final Map<Surface, SurfaceProperties> surfaceProperties;

  // TODO - Rename, document, and make mutable
  final double ioThreshold = 0.1;

  /// Current graph to display in UI
  Graph get activeGraph => _activeGraph;

  /// Currently selected elements
  late final Set<BasePlannerElement> selectedElements = UnmodifiableSetView(
    _selectedElements,
  );

  /// Current active snapshot in [snapshots]
  int get snapshotIndex => _snapshotIndex;

  /// List of saved snapshots. Current snapshot is given by [snapshotIndex]
  late final List<Snapshot> snapshots = UnmodifiableListView(_snapshots);

  SnapshotBuilder? get snapshotBuilder => _snapshotBuilder;

  late Graph _activeGraph;
  final Set<BasePlannerElement> _selectedElements = {};

  final List<Snapshot> _snapshots = [];
  int _snapshotIndex = 0;
  SnapshotBuilder? _snapshotBuilder;

  int _mutationLock = 0;

  BasePlanner(this.db)
    : surfaceProperties = db.surfaceMap.map(
        (name, surface) => MapEntry(
          surface,
          SurfaceProperties._(
            defaultRecipes: surface.recipes.where(
              (recipe) =>
                  recipe.isSimple && recipe.sortedCraftingMachines.isNotEmpty,
            ),
            resources: surface.resourceItems.map((item) => InGameItem(item)),
            availableSolidFuels: surface.resourceItems
                .whereType<SolidItem>()
                .where((solidItem) => (solidItem.fuelValue ?? 0) > 0)
                .map((solidItem) => InGameSolidItem(solidItem)),
          ),
        ),
      ) {
    // Create first snapshot and root graph
    // TODO - root graph should have no surface in space age
    var nauvis = db.surfaceMap['nauvis']!;
    var firstState = GraphStateImpl.rootGraphFirstState(nauvis.icon);
    rootGraph = Graph.rootGraph(this, firstState, nauvis);
    _activeGraph = rootGraph;
    _snapshots.add(
      Snapshot({
        rootGraph: ElementAndState<Graph, GraphStateImpl>(
          rootGraph,
          firstState,
        ),
      }),
    );
  }

  void selectElement(BasePlannerElement element) {
    if (element.parentGraph != _activeGraph) {
      _selectedElements.add(element);
    }
  }

  void deselectElement(BasePlannerElement element) {
    _selectedElements.remove(element);
  }

  void updateActiveGraph(Graph newActiveGraph) {
    if (newActiveGraph != activeGraph) {
      _updateActiveGraph(newActiveGraph);
    }
  }

  /// Throws an exception if mutation is not permitted
  void throwIfMutationNotPermitted() {
    if (_mutationLock == 0) {
      throw const BasePlannerException(
        'State mutation not currently permitted',
      );
    }
  }

  /// Check out a particular snapshot in [snapshots].
  /// Will reset the state of all elements and call
  /// [BasePlannerElement.notifyListeners] where appropriate
  void goToSnapshot(int snapshotIndex) {
    if (snapshotIndex < 0 || snapshotIndex >= _snapshots.length) {
      throw BasePlannerException(
        'Snapshot index $snapshotIndex is out of bounds',
      );
    } else if (snapshotIndex != _snapshotIndex) {
      _applySnapshot(_snapshots[_snapshotIndex], _snapshots[snapshotIndex]);
    }
  }

  /// Any updates to element state via [BasePlannerElement.getChangeTracker]
  /// must happen in here.
  /// Once [function] is complete, states will be saved and a new [Snapshot] will
  /// be created and added to [snapshots].
  /// [snapshotIndex] will be updated to the index of this new snapshot.
  ///
  /// If an error is thrown at any point during this process, the new
  /// snapshot will be abandoned, and all states will be reset to their current
  /// snapshot.
  void buildNextSnapshot(Function function) {
    var firstCall = _mutationLock == 0;
    try {
      _mutationLock++;
      if (firstCall) {
        _snapshotBuilder = SnapshotBuilder.from(_snapshots[_snapshotIndex]);
      }

      function();

      if (firstCall) {
        if (_snapshotBuilder!.performAllQueuedOperationsAndReturnHasChanges()) {
          var newSnapshot = _snapshotBuilder!.build();
          var oldSnapshot = _snapshots[_snapshotIndex];

          if (_snapshotIndex == maxSnapshots - 1) {
            _snapshots.removeAt(0);
          } else {
            _snapshotIndex++;
            _snapshots.removeRange(_snapshotIndex, _snapshots.length);
          }
          _snapshots.add(newSnapshot);

          _applySnapshot(oldSnapshot, newSnapshot);
        }

        _snapshotBuilder = null;
      }

      _mutationLock--;
    } catch (e) {
      if (firstCall) {
        _snapshotBuilder = null;
      }
      _mutationLock--;

      rethrow;
    }
  }

  /// Can only be called within [buildNextSnapshot].
  /// Will throw an exception otherwise
  SnapshotBuilder getSnapshotBuilderOrThrow() {
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

  void _updateActiveGraph(Graph newActiveGraph, [bool updateListeners = true]) {
    _activeGraph = newActiveGraph;
    _selectedElements.clear();

    if (updateListeners) {
      notifyListeners(BasePlannerEvent._(newActiveGraph: true));
    }
  }

  void _applySnapshot(Snapshot oldSnapshot, Snapshot newSnapshot) {
    _mutationLock++;
    try {
      newSnapshot.stateMap.forEach((element, eAndS) {
        eAndS.updateAndNotify(oldSnapshot.stateMap[element]);
      });
      _mutationLock--;

      var removedElements = oldSnapshot.stateMap.keys.toSet().difference(
        newSnapshot.stateMap.keys.toSet(),
      );

      _selectedElements.removeAll(removedElements);
      for (var element in removedElements) {
        element.clearListeners();
      }

      var removedGraphs = removedElements.whereType<Graph>().toSet();
      if (removedGraphs.isNotEmpty) {
        // If _activeGraph was removed, replace it with closest available parent graph
        Graph? newActiveGraph;
        if (removedGraphs.contains(_activeGraph)) {
          newActiveGraph = _activeGraph.parentGraph;
          while (removedGraphs.contains(newActiveGraph)) {
            newActiveGraph = newActiveGraph!.parentGraph;
          }

          _updateActiveGraph(newActiveGraph!, false);
        }

        notifyListeners(
          BasePlannerEvent._(
            removedGraphs: removedGraphs,
            newActiveGraph: newActiveGraph != null,
          ),
        );
      }
    } catch (e) {
      _mutationLock--;
      rethrow;
    }
  }
}

class ElementAndState<E extends BasePlannerElement<St, dynamic>, St> {
  final E element;
  final St state;

  ElementAndState(this.element, this.state);

  void updateAndNotify([ElementAndState<E, St>? oldEAndS]) {
    element.updateState(state);

    if (oldEAndS != null && oldEAndS.state != state) {
      element.notifyListenersOfStateUpdate(oldEAndS.state, state);
    }
  }
}

/// Represents a snapshot of all states of elements in [BasePlanner].
class Snapshot {
  final Map<BasePlannerElement, ElementAndState> stateMap;

  Snapshot(Map<BasePlannerElement, ElementAndState> stateMap)
    : stateMap = Map.unmodifiable(stateMap);
}

class BasePlannerEvent {
  bool newActiveGraph;
  Set<Graph> removedGraphs;

  BasePlannerEvent._({
    this.removedGraphs = const {},
    this.newActiveGraph = false,
  });
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
