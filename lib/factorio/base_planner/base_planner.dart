import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/change_tracker/change_trackers.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/utility/collections.dart';
import 'package:factorio_ratios/utility/json.dart';
import 'package:factorio_ratios/utility/builder.dart';

part 'base_planner_element.dart';

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
class BasePlanner implements ToJson {
  static const maxSnapshots = 20;

  final FactorioDatabase db;
  late final Graph rootGraph;

  final Map<Surface, SurfaceProperties> surfaceProperties;

  /// Contains all items which can be produced by at least one non-recycling recipe
  final SortedItemGroups<Item> validConsumerNodeItems;

  // TODO - Rename, document, and make mutable
  final double ioThreshold = 0.1;

  /// Current active snapshot in [snapshots]
  int get snapshotIndex => _snapshotIndex;

  /// List of saved snapshots. Current snapshot is given by [snapshotIndex]
  late final List<Snapshot> snapshots = UnmodifiableListView(_snapshots);

  SnapshotBuilder? get snapshotBuilder => _snapshotBuilder;

  final List<Snapshot> _snapshots = [];
  int _snapshotIndex = 0;
  SnapshotBuilder? _snapshotBuilder;

  Function(Snapshot oldSnapshot, Snapshot newSnapshot)? _callOnSnapshotUpdate;

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
      ),
      validConsumerNodeItems = SortedItemGroups(
        db.itemMap.values.where(
          (item) => item.producedBy
              .where(
                (recipe) =>
                    !compareLists(recipe.categories, const ['recycling']),
              )
              .isNotEmpty,
        ),
      ) {
    // Create first snapshot and root graph
    // TODO - root graph should have no surface in space age
    var nauvis = db.surfaceMap['nauvis']!;
    var firstState = GraphStateImpl.rootGraphFirstState(nauvis.icon);
    rootGraph = Graph.rootGraph(this, firstState, nauvis);
    _snapshots.add(Snapshot({rootGraph: firstState}));
  }

  void setListener(
    Function(Snapshot oldSnapshot, Snapshot newSnapshot) onSnapshotUpdate,
  ) => _callOnSnapshotUpdate = onSnapshotUpdate;
  void removeListener() => _callOnSnapshotUpdate = null;

  /// Throws an exception if mutation is not permitted
  void throwIfMutationNotPermitted() {
    if (_mutationLock == 0) {
      throw const BasePlannerException(
        'State mutation not currently permitted',
      );
    }
  }

  /// Check out a particular snapshot in [snapshots].
  /// Will reset the state of all elements.
  void goToSnapshot(int newIndex) {
    if (newIndex < 0 || newIndex >= _snapshots.length) {
      throw BasePlannerException('Snapshot index $newIndex is out of bounds');
    } else if (newIndex != _snapshotIndex) {
      _applySnapshot(_snapshots[_snapshotIndex], _snapshots[newIndex]);
      _snapshotIndex = newIndex;
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
        var snapshotBuilder = _snapshotBuilder!;
        snapshotBuilder
          ..performQueuedIoOperations()
          ..performQueuedLayoutUpdates();

        if (snapshotBuilder.hasChanges) {
          var newSnapshot = snapshotBuilder.build();

          int newSnapshotIndex;
          if (_snapshotIndex == maxSnapshots - 1) {
            _snapshots.removeAt(0);
            newSnapshotIndex = _snapshotIndex;
          } else {
            _snapshots.removeRange(_snapshotIndex, _snapshots.length);
            newSnapshotIndex = _snapshotIndex + 1;
          }
          _snapshots.add(newSnapshot);

          _applySnapshot(_snapshots[_snapshotIndex], newSnapshot);
          _snapshotIndex = newSnapshotIndex;
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

  void _applySnapshot(Snapshot oldSnapshot, Snapshot newSnapshot) {
    try {
      _mutationLock++;
      newSnapshot.stateMap.forEach(
        (element, state) => element.updateState(state),
      );
      _mutationLock--;
    } catch (e) {
      _mutationLock--;
      rethrow;
    }

    _callOnSnapshotUpdate?.call(oldSnapshot, newSnapshot);
  }
}

/// Represents a snapshot of all states of elements in [BasePlanner].
class Snapshot {
  final Map<BasePlannerElement, Object> stateMap;

  Snapshot(Map<BasePlannerElement, Object> stateMap)
    : stateMap = Map.unmodifiable(stateMap);

  Object? operator [](BasePlannerElement? key) => stateMap[key];
  bool containsKey(BasePlannerElement? key) => stateMap.containsKey(key);
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
