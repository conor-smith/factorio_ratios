import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:flutter/widgets.dart';

class BasePlannerModel extends InheritedModel<BasePlannerModelAspect> {
  final BasePlannerData _data;

  Snapshot get activeSnapshot => _data.activeSnapshot;
  bool get selectionUpdate => _data.selectionUpdate;
  Set<BasePlannerElement> get selectedElements => _data.selectedElements;
  GeometryOperation? get geometryOperation => _data.geometryOperation;
  Widget? get overlayMenu => _data.overlayMenu;

  const BasePlannerModel({
    super.key,
    required BasePlannerData data,
    required super.child,
  }) : _data = data;

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
        selectionUpdate &&
            oldModel.selectedElements.contains(aspect.element) !=
                selectedElements.contains(aspect.element),

      DependencyType.activeElement => selectionUpdate,

      DependencyType.geometryOp => geometryOperation != null,
    },
  );
}

class BasePlannerData {
  final Snapshot activeSnapshot;

  final bool selectionUpdate;
  final Set<BasePlannerElement> selectedElements;
  final BasePlannerElement? activeElement;

  final GeometryOperation? geometryOperation;

  final Widget? overlayMenu;

  const BasePlannerData._({
    required this.activeSnapshot,
    required this.selectionUpdate,
    required this.selectedElements,
    required this.activeElement,
    required this.geometryOperation,
    required this.overlayMenu,
  });

  const BasePlannerData.initial({
    required Snapshot activeSnapshot,
    required Graph activeGraph,
  }) : this._(
         activeSnapshot: activeSnapshot,
         selectionUpdate: true,
         activeElement: null,
         selectedElements: const {},
         geometryOperation: null,
         overlayMenu: null,
       );

  factory BasePlannerData.update({
    required BasePlannerData oldModel,
    Snapshot? newSnapshot,
    Set<BasePlannerElement>? newSelection,
    bool nullableActiveElement = false,
    BasePlannerElement? newActiveElement,
    GeometryOperation? geometryOp,
    Widget? overlayMenu,
  }) {
    var activeSnapshot = newSnapshot ?? oldModel.activeSnapshot;

    Set<BasePlannerElement> selectedElements = newSelection != null
        ? Set.unmodifiable(newSelection)
        : oldModel.selectedElements;

    BasePlannerElement? activeElement;
    if (newActiveElement == null) {
      activeElement = nullableActiveElement ? null : oldModel.activeElement;
    } else {
      activeElement = newActiveElement;
    }
    var selectionUpdate =
        newSelection != null || activeElement != oldModel.activeElement;

    return BasePlannerData._(
      activeSnapshot: activeSnapshot,
      selectionUpdate: selectionUpdate,
      selectedElements: selectedElements,
      activeElement: activeElement,
      geometryOperation: geometryOp,
      overlayMenu: overlayMenu,
    );
  }
}

enum DependencyType { stateChange, selectionToggle, activeElement, geometryOp }

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
