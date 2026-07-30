import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
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
  late BasePlannerData activeData;

  final List<NodeElement> orderedNodes = [];
  final List<Edge> orderedEdges = [];

  final Set<BasePlannerElement> selectedElements = {};

  bool allowTransformation = true;

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

    activeData = BasePlannerData.initial(
      activeSnapshot: widget.basePlanner.snapshots.last,
      activeGraph: widget.basePlanner.rootGraph,
    );
  }

  void toggleSelect<T extends BasePlannerElement>(
    T element,
    bool clearPreviousSelection,
    List<T> orderedElements,
  ) {
    if (element == activeData.activeElement &&
        selectedElements.length == 1 &&
        clearPreviousSelection) {
      // User clicked on already selected element. No action needed
      return;
    }

    setState(() {
      BasePlannerElement? activeElement = activeData.activeElement;

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

      activeData = BasePlannerData.update(
        oldModel: activeData,
        newSelection: selectedElements,
        nullableActiveElement: true,
        newActiveElement: activeElement,
      );
    });
  }

  void clearSelectedElements() {
    if (selectedElements.isNotEmpty) {
      setState(() {
        selectedElements.clear();
        activeData = BasePlannerData.update(
          oldModel: activeData,
          newSelection: selectedElements,
          nullableActiveElement: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Placeholder());
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
