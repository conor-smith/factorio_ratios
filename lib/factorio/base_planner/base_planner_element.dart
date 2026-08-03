part of 'base_planner.dart';

/// All objects that are part of [BasePlanner] implement this interface.
///
/// As all elements are listenable, state changes should only be
/// registered via events.
abstract class BasePlannerElement<St> implements ToJson {
  final BasePlanner basePlanner;

  BasePlannerElement(this.basePlanner);

  Graph get parentGraph;
  Geometry get geometry;
  ElementType get elementType;

  /// Will only be permitted if [BasePlanner] allows. Will throw an exception otherwise.
  void updateState(St newState);

  ElementChangeTracker getChangeTracker();
  Builder<St> getStateBuilder();
}

enum ElementType { graph, prodLineNode, edge }
