import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/utility/collections.dart' as utility;
import 'package:flutter/widgets.dart';

/// Tracks state updates to individual elements.
/// Updates said elements accordingly.
class BasePlannerModel extends InheritedModel<BasePlannerModelAspect> {
  final Snapshot activeSnapshot;
  final Graph activeGraph;
  final List<BasePlannerElement> orderedSelectedElements;
  final Set<BasePlannerElement> selectedElements;
  final GeometryOperation? geometryOperation;

  BasePlannerModel({
    super.key,
    required super.child,
    required this.activeSnapshot,
    required this.activeGraph,
    required Iterable<BasePlannerElement> orderedSelectedElements,
    this.geometryOperation,
  }) : orderedSelectedElements = List.unmodifiable(orderedSelectedElements),
       selectedElements = Set.unmodifiable(orderedSelectedElements);

  @override
  bool updateShouldNotify(BasePlannerModel oldModel) => oldModel != this;

  @override
  bool updateShouldNotifyDependent(
    BasePlannerModel oldModel,
    Set<BasePlannerModelAspect> aspects,
  ) => aspects.any(
    (aspect) => switch (aspect.dependencyType) {
      DependencyType.stateChange =>
        oldModel.activeSnapshot != activeSnapshot &&
            oldModel.activeSnapshot.stateMap[aspect.element] !=
                activeSnapshot.stateMap[aspect.element],

      DependencyType.selectionToggle =>
        oldModel.selectedElements.contains(aspect.element) !=
            selectedElements.contains(aspect.element),

      DependencyType.selectionOrder => !utility.compareLists(
        oldModel.orderedSelectedElements,
        orderedSelectedElements,
      ),

      DependencyType.geometryOp =>
        oldModel.geometryOperation != geometryOperation,
    },
  );
}

enum DependencyType { stateChange, selectionToggle, selectionOrder, geometryOp }

class BasePlannerModelAspect {
  final DependencyType dependencyType;
  final BasePlannerElement element;

  const BasePlannerModelAspect(this.dependencyType, this.element);

  @override
  bool operator ==(Object other) {
    return super == other ||
        (other is BasePlannerModelAspect &&
            other.dependencyType == dependencyType &&
            other.element == element);
  }

  @override
  int get hashCode => element.hashCode + dependencyType.hashCode;
}
