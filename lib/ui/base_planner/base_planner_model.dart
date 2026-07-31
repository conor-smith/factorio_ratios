import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:flutter/widgets.dart';

class BasePlannerModel extends InheritedModel<BasePlannerModelAspect> {
  final Snapshot activeSnapshot;
  final Graph activeGraph;

  final int orderedNodesHash;
  final List<NodeElement> orderedNodes;

  final int orderedEdgesHash;
  final List<Edge> orderedEdges;

  final int selectedElementsHash;
  final Set<BasePlannerElement> selectedElements;
  final BasePlannerElement? activeElement;

  final GeometryOperation? geometryOp;

  factory BasePlannerModel({
    Key? key,
    required Snapshot activeSnapshot,
    required Graph activeGraph,
    required List<NodeElement> orderedNodes,
    required List<Edge> orderedEdges,
    required Set<BasePlannerElement> selectedElements,
    required BasePlannerElement? activeElement,
    required GeometryOperation? geometryOp,
    required Widget child,
  }) {
    var orderedNodesHash = 0;
    for (var i = 0; i < orderedNodes.length; i++) {
      orderedNodesHash += orderedNodes[i].hashCode * (i + 1);
    }

    var orderedEdgesHash = 0;
    for (var i = 0; i < orderedEdges.length; i++) {
      orderedEdgesHash += orderedEdges[i].hashCode * (i + 1);
    }

    var selectedElementsHash = selectedElements.fold(
      0,
      (hash, element) => hash += element.hashCode,
    );

    return BasePlannerModel._(
      key: key,
      activeSnapshot: activeSnapshot,
      activeGraph: activeGraph,
      orderedNodesHash: orderedNodesHash,
      orderedNodes: orderedNodes,
      orderedEdgesHash: orderedEdgesHash,
      orderedEdges: orderedEdges,
      selectedElementsHash: selectedElementsHash,
      selectedElements: Set.unmodifiable(selectedElements),
      activeElement: activeElement,
      geometryOp: geometryOp,
      child: child,
    );
  }

  const BasePlannerModel._({
    super.key,
    required this.activeSnapshot,
    required this.activeGraph,
    required this.orderedNodesHash,
    required this.orderedNodes,
    required this.orderedEdgesHash,
    required this.orderedEdges,
    required this.selectedElementsHash,
    required this.selectedElements,
    required this.activeElement,
    required this.geometryOp,
    required super.child,
  });

  @override
  bool updateShouldNotify(BasePlannerModel oldModel) => oldModel != this;

  @override
  bool updateShouldNotifyDependent(
    BasePlannerModel oldModel,
    Set<BasePlannerModelAspect> aspects,
  ) => aspects.any(
    (aspect) => switch (aspect.dependencyType) {
      DependencyType.stateChange =>
        activeSnapshot[aspect.element] !=
            oldModel.activeSnapshot[aspect.element],

      DependencyType.selectionToggle =>
        selectedElementsHash != oldModel.selectedElementsHash &&
            selectedElements.contains(aspect.element) !=
                oldModel.selectedElements.contains(aspect.element),

      DependencyType.activeElement =>
        activeElement != oldModel.activeElement &&
            (aspect.element == activeElement) !=
                (aspect.element == oldModel.activeElement),

      DependencyType.geometryOp =>
        geometryOp?.containsElement(aspect.element) ?? false,
    },
  );
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
