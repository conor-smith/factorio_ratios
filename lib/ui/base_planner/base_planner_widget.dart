import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_model.dart';
import 'package:flutter/material.dart';

class BasePlannerWidget extends StatefulWidget {
  final BasePlanner basePlanner;

  const BasePlannerWidget({super.key, required this.basePlanner});

  @override
  State<BasePlannerWidget> createState() => _BasePlannerWidgetState();
}

class _BasePlannerWidgetState extends State<BasePlannerWidget> {
  late Snapshot activeSnapshot;
  late Graph activeGraph;

  final List<NodeElement> orderedNodes = [];
  final List<Edge> orderedEdges = [];

  final Set<BasePlannerElement> selectedElements = {};
  BasePlannerElement? activeElement;

  GeometryOperation? geometryOp;

  Widget? overlayMenu;

  static _BasePlannerWidgetState _getStateOrThrow(BuildContext context) {
    var state = context.findAncestorStateOfType<_BasePlannerWidgetState>();

    if (state == null) {
      throw const FactorioException('Base planner widget not found in tree');
    } else {
      return state;
    }
  }

  @override
  void initState() {
    super.initState();

    activeSnapshot =
        widget.basePlanner.snapshots[widget.basePlanner.snapshotIndex];
    activeGraph = widget.basePlanner.rootGraph;

    widget.basePlanner.setListener(snapshotUpdate);
  }

  @override
  void dispose() {
    super.dispose();

    widget.basePlanner.removeListener();
  }

  void snapshotUpdate(Snapshot oldSnapshot, Snapshot newSnapshot) => setState(
    () {
      activeSnapshot = newSnapshot;

      if (!newSnapshot.containsKey(activeGraph)) {
        do {
          activeGraph = activeGraph.parentGraph;
        } while (!newSnapshot.containsKey(activeGraph) && !activeGraph.isRoot);

        activeElement = null;
        selectedElements.clear();
        orderedNodes
          ..clear()
          ..addAll(activeGraph.allNodes);
        orderedEdges
          ..clear()
          ..addAll(activeGraph.edges);
      } else if (activeGraph.allElementsHash !=
          (oldSnapshot[activeGraph] as GraphStateImpl?)?.allElementsHash) {
        orderedNodes
          ..removeWhere((node) => !activeGraph.allNodes.contains(node))
          ..addAll(
            activeGraph.allNodes
                .where((node) => !orderedNodes.contains(node))
                .toList(),
          );
        orderedEdges
          ..removeWhere((edge) => !activeGraph.edges.contains(edge))
          ..addAll(
            activeGraph.edges
                .where((edge) => !orderedEdges.contains(edge))
                .toList(),
          );
      }
    },
  );

  void toggleSelect<T extends BasePlannerElement>(
    T element,
    bool clearPreviousSelection,
    List<T> orderedElements,
  ) {
    if (element == activeElement &&
        selectedElements.length == 1 &&
        clearPreviousSelection) {
      // User clicked on already selected element. No action needed
      return;
    }

    setState(() {
      if (clearPreviousSelection) {
        selectedElements
          ..clear()
          ..add(element);
        orderedElements
          ..remove(element)
          ..add(element);
        activeElement = element;
      } else if (!selectedElements.contains(element)) {
        selectedElements.add(element);
        orderedElements
          ..remove(element)
          ..add(element);
        activeElement = element;
      } else {
        selectedElements.remove(element);
        if (element == activeElement) {
          activeElement = null;
        }
      }
    });
  }

  void clearSelectedElements() {
    if (selectedElements.isNotEmpty) {
      setState(() {
        selectedElements.clear();
        activeElement = null;
      });
    }
  }

  Widget? popOverlayMenu() {
    var poppedMenu = overlayMenu;
    overlayMenu = null;
    return poppedMenu;
  }

  GeometryOperation? popGeometryOp() {
    var poppedOp = geometryOp;
    geometryOp = null;
    return poppedOp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BasePlannerModel(
        activeSnapshot: activeSnapshot,
        activeGraph: activeGraph,
        orderedNodes: orderedNodes,
        orderedEdges: orderedEdges,
        selectedElements: selectedElements,
        activeElement: activeElement,
        geometryOp: popGeometryOp(),
        child: const Placeholder(),
      ),
    );
  }
}

// TODO: Document
void toggleSelectNode(
  BuildContext context,
  NodeElement node,
  bool clearPreviousSelection,
) {
  var state = _BasePlannerWidgetState._getStateOrThrow(context);
  state.toggleSelect(node, clearPreviousSelection, state.orderedNodes);
}

void toggleSelectEdge(
  BuildContext context,
  Edge edge,
  bool clearPreviousSelection,
) {
  var state = _BasePlannerWidgetState._getStateOrThrow(context);
  state.toggleSelect(edge, clearPreviousSelection, state.orderedEdges);
}

void clearSelectedElements(BuildContext context) =>
    _BasePlannerWidgetState._getStateOrThrow(context).clearSelectedElements();
