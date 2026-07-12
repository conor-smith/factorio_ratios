part of 'base_planner.dart';

/// All objects that are part of [BasePlanner] implement this interface.
///
/// As all elements are listenable, state changes should only be
/// registered via events.
abstract class BasePlannerElement<St, E>
    with EventNotifier<E>
    implements ToJson {
  final BasePlanner basePlanner;

  BasePlannerElement(this.basePlanner);

  Graph get parentGraph;
  Geometry get geometry;

  bool get isSelected;
  void select();
  void deselect();

  Dependencies determineDependencies();
  Iterable<BasePlannerElement> determineDependants();

  /// Will only be permitted if [BasePlanner] allows. Will throw an exception otherwise.
  void updateState(St state);

  /// Return mutable object representing [state].
  /// All changes will be reflected unless [cancelStateBuilder] is called.
  StateBuilder<St> getStateBuilder();
  void cancelStateBuilder();

  /// Used in the event of a dragging or resizing operation.
  /// Allows notifying listeners of some [Geometry] object without updating [state].
  void notifyListenersOfGeometryUpdate(covariant Geometry geometry);

  /// Used whenever state is updated
  void notifyListenersOfStateUpdate(St oldState, St newState);

  /// Updates relevant fields for item input output.
  /// Returns true if update occurred, false otherwise
  bool calculateIo(covariant Dependencies dependencies);

  void checkForCircularDependencies(
    Set<BasePlannerElement> safeElements,
    Set<BasePlannerElement> visitedElements,
  ) {
    if (visitedElements.contains(this)) {
      throw BasePlannerException('Circular dependency detected at $this');
    }

    if (!safeElements.contains(this)) {
      visitedElements.add(this);

      var dependencies = basePlanner.getSnapshotBuilder().getCachedDependencies(
        this,
      );

      for (var dependency in dependencies.allDependencies) {
        dependency.checkForCircularDependencies(safeElements, visitedElements);
      }

      visitedElements.remove(this);
      safeElements.add(this);
    }
  }
}

abstract interface class Dependencies {
  Iterable<BasePlannerElement> get allDependencies;
}
