import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:flutter/material.dart' hide Icon;
import 'package:flutter/services.dart';

const List<LogicalKeyboardKey> _shiftKeys = [
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.shift,
];

class GraphOverlayWidget extends StatelessWidget {
  final OverlayChangeNotifier changeNotifier;

  GraphOverlayWidget({super.key, required Graph graph})
    : changeNotifier = OverlayChangeNotifier(graph);

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class GraphWidget extends StatefulWidget {
  final GraphWidgetPersistentState persistentState;

  const GraphWidget({super.key, required this.persistentState});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  Graph get graph => widget.persistentState.graph;
  List<BasePlannerElement> get elementDisplayOrder =>
      widget.persistentState.elementDisplayOrder;

  final FocusNode focusNode = FocusNode();
  bool shiftKeyHeld = false;

  final Map<BasePlannerElement, ElementViewChangeNotifier> changeNotifiers = {};
  final Map<BasePlannerElement, Widget> elementWidgets = {};
  List<Widget>? cachedWidgetList;

  late final GraphOverlayWidget graphOverlay = GraphOverlayWidget(graph: graph);

  GeometryOperation? geometryOp;
  bool allowTransformation = true;
  bool elementPointerOperation = false;
  bool hasBeenInitiated = false;

  @override
  void initState() {
    super.initState();

    onSnapshotUpdate();
    for (var element in elementDisplayOrder) {
      switch (element.elementType) {
        case ElementType.graph:
        case ElementType.prodLineNode:
          var notifier = NodeChangeNotifier(element as NodeElement);
          changeNotifiers[element] = notifier;
          elementWidgets[element] = NodeWidget(notifier: notifier);

        case ElementType.edge:
          var notifier = EdgeChangeNotifier(element as Edge);
          changeNotifiers[element] = notifier;
          elementWidgets[element] = EdgeWidget(notifier: notifier);
      }
    }

    graph.basePlanner.addListener(onSnapshotUpdate);
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    super.dispose();

    graph.basePlanner.removeListener(onSnapshotUpdate);
    focusNode.dispose();
    for (var notifier in changeNotifiers.values) {
      notifier.dispose();
    }
  }

  void onSnapshotUpdate() {
    if (graph.allElementsHash != widget.persistentState._allElementsHash) {
      widget.persistentState._allElementsHash = graph.allElementsHash;

      elementDisplayOrder.removeWhere((element) {
        if (!graph.allNodes.contains(element) &&
            graph.edges.contains(element)) {
          changeNotifiers.remove(element);
          elementWidgets.remove(element);
          return true;
        } else {
          return false;
        }
      });

      var newNodes = graph.allNodes
          .where((node) => !changeNotifiers.containsKey(node))
          .toList();
      var newEdges = graph.edges
          .where((edge) => !changeNotifiers.containsKey(edge))
          .toList();

      // Insert new elements in under currently selected elements
      int firstUnselectedIndex;
      for (
        firstUnselectedIndex = elementDisplayOrder.length - 1;
        firstUnselectedIndex >= 0;
        firstUnselectedIndex--
      ) {
        if (!changeNotifiers[elementDisplayOrder[firstUnselectedIndex]]!
            .selected) {
          break;
        }
      }
      elementDisplayOrder.insertAll(firstUnselectedIndex + 1, [
        ...newEdges,
        ...newNodes,
      ]);

      if (hasBeenInitiated) {
        setState(() {
          for (var newNode in newNodes) {
            var nodeChangeNotifier = NodeChangeNotifier(newNode);
            changeNotifiers[newNode] = nodeChangeNotifier;
            elementWidgets[newNode] = NodeWidget(notifier: nodeChangeNotifier);
          }

          for (var newEdge in newEdges) {
            var edgeChangeNotifier = EdgeChangeNotifier(newEdge);
            changeNotifiers[newEdge] = edgeChangeNotifier;
            elementWidgets[newEdge] = EdgeWidget(notifier: edgeChangeNotifier);
          }

          cachedWidgetList = null;
        });
      }
    }

    if (hasBeenInitiated) {
      for (var elementChangeNotifier in [
        ...changeNotifiers.values,
        graphOverlay.changeNotifier,
      ]) {
        elementChangeNotifier.newSnapshot();
      }
    }

    hasBeenInitiated = true;
  }

  void handleTrasformationState() {
    var newAllowTransformation =
        !shiftKeyHeld && !elementPointerOperation && geometryOp == null;

    if (newAllowTransformation != allowTransformation) {
      setState(() {
        allowTransformation = newAllowTransformation;
      });
    }
  }

  void beginElementPointerOperation() {
    elementPointerOperation = true;

    handleTrasformationState();
  }

  void endElementPointerOperation() {
    elementPointerOperation = false;

    handleTrasformationState();
  }

  void handleKeyEvent(KeyEvent event) {
    if (_shiftKeys.contains(event.logicalKey)) {
      if (event is KeyDownEvent) {
        shiftKeyHeld = true;
      } else if (event is KeyUpEvent) {
        shiftKeyHeld = false;
      }

      handleTrasformationState();
    }
  }

  void toggleSelection(BasePlannerElement toToggle) {
    var toToggleNotifier = changeNotifiers[toToggle]!;
    var selectedElementNotifiers = changeNotifiers.values
        .where((notifier) => notifier.selected)
        .toList();

    if (toToggleNotifier.isActiveElement &&
        selectedElementNotifiers.length == 1 &&
        !shiftKeyHeld) {
      // User clicked on the selected element again. No change needed
      return;
    } else if (!shiftKeyHeld) {
      // Unselect all other elements, and make toToggle activeElement
      for (var selected in selectedElementNotifiers.where(
        (notifier) => notifier != toToggleNotifier,
      )) {
        selected.updateSelectedState(false, false);
      }

      toToggleNotifier.updateSelectedState(true, true);

      if (elementDisplayOrder.last != toToggle) {
        setState(() {
          elementDisplayOrder
            ..remove(toToggle)
            ..add(toToggle);

          cachedWidgetList = null;
        });
      }
    } else if (!toToggleNotifier.isActiveElement) {
      // shiftKeyHeld = true
      // select toToggle and make activeElement. Clear previous activeElement
      // Move to front of display
      selectedElementNotifiers
          .where((notifier) => notifier.isActiveElement)
          .firstOrNull
          ?.updateSelectedState(true, false);

      toToggleNotifier.updateSelectedState(true, true);

      if (elementDisplayOrder.last != toToggle) {
        setState(() {
          elementDisplayOrder
            ..remove(toToggle)
            ..add(toToggle);

          cachedWidgetList = null;
        });
      }
    } else {
      // shiftKeyHeld == true and toToggleNotifier.isActiveElement == true
      // Deselect toToggle only
      toToggleNotifier.updateSelectedState(false, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    cachedWidgetList ??= elementDisplayOrder
        .map((element) => elementWidgets[element]!)
        .toList(growable: false);

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: handleKeyEvent,
      child: InteractiveViewer(
        panEnabled: allowTransformation,
        scaleEnabled: allowTransformation,
        child: Stack(children: cachedWidgetList!),
      ),
    );
  }
}

class OverlayChangeNotifier extends ElementChangeNotifier {
  final Graph graph;

  String _name;
  Icon? _icon;

  OverlayChangeNotifier(this.graph) : _name = graph.name, _icon = graph.icon;

  String get name => _name;
  Icon? get icon => _icon;

  @override
  void newSnapshot() {
    var newName = graph.name;
    var newIcon = graph.icon;

    if (newName != _name || newIcon != _icon) {
      _name = newName;
      _icon = newIcon;
      notifyListeners();
    }
  }
}

class GraphWidgetPersistentState {
  final Graph graph;
  final TransformationController controller;
  final List<BasePlannerElement> elementDisplayOrder;

  int _allElementsHash;

  GraphWidgetPersistentState(this.graph)
    : controller = TransformationController(),
      elementDisplayOrder = [...graph.edges, ...graph.allNodes],
      _allElementsHash = graph.allElementsHash;
}

abstract class ElementViewChangeNotifier extends ElementChangeNotifier {
  bool _selected;
  bool _isActiveElement;
  GeometryOperation? geometryOp;

  ElementViewChangeNotifier()
    : _selected = false,
      _isActiveElement = false,
      geometryOp = null;

  bool get selected => _selected;
  bool get isActiveElement => _isActiveElement;

  void updateSelectedState(bool selected, bool isActiveElement) {
    if (selected != _selected || isActiveElement != _isActiveElement) {
      _selected = selected;
      _isActiveElement = isActiveElement;
      notifyListeners();
    }
  }

  GeometryOperation? popGeometryOp();

  void checkForBuilder(GeometryOperation geometryOp);
}

_GraphWidgetState _getStateOrThrow(BuildContext context) {
  var state = context.findAncestorStateOfType<_GraphWidgetState>();

  if (state == null) {
    throw const BasePlannerException('Graph widget not found in context');
  }

  return state;
}

void selectToggle(BuildContext context, BasePlannerElement element) =>
    _getStateOrThrow(context).toggleSelection(element);

void beginElementPointerOperation(BuildContext context) =>
    _getStateOrThrow(context).beginElementPointerOperation();
void endElementPointerOperation(BuildContext context) =>
    _getStateOrThrow(context).endElementPointerOperation();

// class GraphOverlay extends StatelessWidget {
//   const GraphOverlay({super.key});

//   @override
//   Widget build(BuildContext context) {
//     var model = BasePlannerModel.of(
//       context,
//       BasePlannerModelAspect(DependencyType.graphOverlay),
//     );

//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             border: Border(bottom: BorderSide(color: Colors.black)),
//           ),
//           child: Row(
//             children: [
//               Padding(
//                 padding: EdgeInsetsGeometry.all(5),
//                 child: IconWidgetCache.get(model.activeGraphIcon),
//               ),
//               Text(model.activeGraphName),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class GraphWindow extends StatelessWidget {
//   const GraphWindow({super.key});

//   void createContextMenu(
//     BuildContext context,
//     Graph activeGraph,
//     Offset screenPosition,
//     Offset graphPosition,
//   ) {
//     pushOverlayMenu(
//       context,
//       ContextMenu(
//         screenLocation: screenPosition,
//         options: [
//           MenuOption(
//             text: 'Create consumer node',
//             operation: (ctx) =>
//                 createConsumerMenu(ctx, graphPosition, activeGraph),
//           ),
//           MenuOption(
//             text: 'Build full graph',
//             operation: (_) => activeGraph.fulfillAllNodeIo(),
//           ),
//         ],
//       ),
//     );
//   }

//   void createConsumerMenu(
//     BuildContext context,
//     Offset graphPosition,
//     Graph activeGraph,
//   ) {
//     pushOverlayMenu(
//       context,
//       Center(
//         child: FactorioIconMenuWidget<Item>(
//           itemGroups: activeGraph.basePlanner.validConsumerNodeItems,
//           onSelected: (item) {
//             activeGraph.addNode(
//               nodeType: NodeType.consumer,
//               productionLine: MagicLine.singleItemConsumer(InGameItem(item)),
//               initialPosition: graphPosition,
//             );
//           },
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     var model = BasePlannerModel.of(
//       context,
//       BasePlannerModelAspect(DependencyType.graphView),
//     );

//     List<NodeElement> unselectedNodes;
//     List<NodeElement> selectedNodes;
//     List<Edge> unselectedEdges;
//     List<Edge> selectedEdges;

//     if (model.selectedElements.isEmpty) {
//       unselectedNodes = model.orderedNodes;
//       unselectedEdges = model.orderedEdges;
//       selectedNodes = const [];
//       selectedEdges = const [];
//     } else {
//       unselectedNodes = [];
//       selectedNodes = [];
//       for (var node in model.orderedNodes) {
//         if (!model.selectedElements.contains(node)) {
//           unselectedNodes.add(node);
//         } else {
//           selectedNodes.add(node);
//         }
//       }

//       unselectedEdges = [];
//       selectedEdges = [];
//       for (var edge in model.orderedEdges) {
//         if (!model.selectedElements.contains(edge)) {
//           unselectedEdges.add(edge);
//         } else {
//           selectedEdges.add(edge);
//         }
//       }
//     }

//     return InteractiveViewer(
//       panEnabled: model.allowTransformation,
//       scaleEnabled: model.allowTransformation,
//       child: Stack(
//         fit: StackFit.expand,
//         clipBehavior: Clip.none,
//         children: [
//           GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onSecondaryTapUp: (details) {
//               if (!isShiftKeyHeld(context)) {
//                 createContextMenu(
//                   context,
//                   model.activeGraph,
//                   details.globalPosition,
//                   details.localPosition,
//                 );
//               }
//             },
//           ),
//           ...unselectedEdges.map(
//             (edge) => EdgeWidget(key: BasePlannerElementKey(edge), edge: edge),
//           ),
//           ...unselectedNodes.map(
//             (node) => NodeWidget(key: BasePlannerElementKey(node), node: node),
//           ),
//           ...selectedEdges.map(
//             (edge) => EdgeWidget(key: BasePlannerElementKey(edge), edge: edge),
//           ),
//           ...selectedNodes.map(
//             (node) => NodeWidget(key: BasePlannerElementKey(node), node: node),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ContextMenu extends StatelessWidget {
//   final Offset screenLocation;
//   final List<MenuOption> options;

//   const ContextMenu({
//     super.key,
//     required this.screenLocation,
//     required this.options,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: screenLocation.dy,
//       left: screenLocation.dx,
//       child: IntrinsicWidth(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: options,
//         ),
//       ),
//     );
//   }
// }

// class MenuOption extends StatelessWidget {
//   final String text;
//   final Function(BuildContext context) operation;

//   const MenuOption({super.key, required this.text, required this.operation});

//   @override
//   Widget build(BuildContext context) {
//     return TextButton(onPressed: () => operation(context), child: Text(text));
//   }
// }

// class BasePlannerElementKey extends LocalKey {
//   final BasePlannerElement element;

//   const BasePlannerElementKey(this.element);

//   @override
//   bool operator ==(Object other) =>
//       super == other ||
//       (other is BasePlannerElementKey && other.element == element);

//   @override
//   int get hashCode => element.hashCode;
// }
