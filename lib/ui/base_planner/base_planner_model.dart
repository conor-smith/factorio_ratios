import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:flutter/widgets.dart' hide Icon;

class BasePlannerModel extends InheritedModel<BasePlannerModelAspect> {
  final Snapshot activeSnapshot;
  final Graph activeGraph;
  final String activeGraphName;
  final Icon? activeGraphIcon;

  final int orderedNodesHash;
  final List<NodeElement> orderedNodes;

  final int orderedEdgesHash;
  final List<Edge> orderedEdges;

  final int selectedElementsHash;
  final Set<BasePlannerElement> selectedElements;
  final BasePlannerElement? activeElement;

  final GeometryOperation? geometryOp;

  final bool allowTransformation;

  factory BasePlannerModel({
    Key? key,
    required Snapshot activeSnapshot,
    required Graph activeGraph,
    required List<NodeElement> orderedNodes,
    required List<Edge> orderedEdges,
    required Set<BasePlannerElement> selectedElements,
    required BasePlannerElement? activeElement,
    required GeometryOperation? geometryOp,
    required bool allowTransformation,
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
      allowTransformation: allowTransformation,
      child: child,
    );
  }

  BasePlannerModel._({
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
    required this.allowTransformation,
    required super.child,
  }) : activeGraphName = activeGraph.name,
       activeGraphIcon = activeGraph.icon;

  bool _stateUpdate(BasePlannerModel oldModel, BasePlannerElement element) =>
      activeSnapshot[element] != oldModel.activeSnapshot[element];
  bool _selectionUpdate(
    BasePlannerModel oldModel,
    BasePlannerElement element,
  ) =>
      selectedElementsHash != oldModel.selectedElementsHash &&
      (selectedElements.contains(element) !=
              oldModel.selectedElements.contains(element) ||
          (element == activeElement) != (element == oldModel.activeElement));
  bool _geometryOpOnElement(BasePlannerElement element) =>
      geometryOp?.containsElement(element) ?? false;

  @override
  bool updateShouldNotify(BasePlannerModel oldModel) => oldModel != this;

  @override
  bool updateShouldNotifyDependent(
    BasePlannerModel oldModel,
    Set<BasePlannerModelAspect> aspects,
  ) => aspects.any(
    (aspect) => switch (aspect.dependencyType) {
      DependencyType.elementWidget =>
        _stateUpdate(oldModel, aspect.element) ||
            _selectionUpdate(oldModel, aspect.element) ||
            _geometryOpOnElement(aspect.element),

      DependencyType.graphView =>
        activeGraph != oldModel.activeGraph ||
            orderedNodesHash != oldModel.orderedNodesHash ||
            orderedEdgesHash != oldModel.orderedEdgesHash,

      DependencyType.graphOverlay =>
        activeGraphName != oldModel.activeGraphName ||
            activeGraphIcon != oldModel.activeGraphIcon,
    },
  );
}

enum DependencyType { elementWidget, graphView, graphOverlay }

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
