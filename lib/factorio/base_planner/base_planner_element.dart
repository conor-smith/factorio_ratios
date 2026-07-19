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

  /// Will only be permitted if [BasePlanner] allows. Will throw an exception otherwise.
  void updateState(St state);

  ElementChangeTracker getChangeTracker();
  Builder<St> getStateBuilder();

  /// Used in the event of a dragging or resizing operation.
  /// Allows notifying listeners of some [Geometry] object without updating state
  void notifyListenersOfGeometryUpdate(covariant Geometry geometry);

  void notifyListenersOfStateUpdate(St oldState, St newState);

  void notifyListenersOfSelectionUpdate();

  bool get isSelected => parentGraph.selectedElements.contains(this);

  void selectToggle(bool clearPreviousSelection) {
    var isSelectedAtStart = isSelected;

    if (clearPreviousSelection) {
      parentGraph.clearSelected(true);
    }

    if (!isSelectedAtStart) {
      parentGraph.addToSelected(this);
    } else if (isSelectedAtStart && !clearPreviousSelection) {
      parentGraph.removeFromSelected(this);
    }
  }
}

abstract interface class Dependencies {
  Iterable<BasePlannerElement> get allElements;
}
