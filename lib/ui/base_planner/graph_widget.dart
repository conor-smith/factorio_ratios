import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:flutter/material.dart' hide Icon;

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
  List<NodeElement> get nodeDisplayOrder =>
      widget.persistentState.nodeDisplayOrder;
  List<Edge> get edgeDisplayOrder => widget.persistentState.edgeDisplayOrder;

  final Set<BasePlannerElement> selectedElements = {};
  BasePlannerElement? activeElement;

  final Map<NodeElement, NodeWidget> nodeWidgets = {};
  final Map<Edge, EdgeWidget> edgeWidgets = {};
  late final GraphOverlayWidget graphOverlay = GraphOverlayWidget(graph: graph);

  bool hasBeenInitiated = false;

  @override
  void initState() {
    super.initState();

    onSnapshotUpdate();

    for (var node in nodeDisplayOrder) {
      nodeWidgets[node] = NodeWidget(node: node);
    }
    for (var edge in edgeDisplayOrder) {
      edgeWidgets[edge] = EdgeWidget(edge: edge);
    }

    graph.basePlanner.addListener(onSnapshotUpdate);
  }

  @override
  void dispose() {
    super.dispose();

    graph.basePlanner.removeListener(onSnapshotUpdate);
  }

  void onSnapshotUpdate() {
    if (graph.allElementsHash != widget.persistentState._allElementsHash) {
      widget.persistentState._allElementsHash = graph.allElementsHash;

      if (activeElement != null &&
          !graph.allNodes.contains(activeElement) &&
          !graph.edges.contains(activeElement)) {
        activeElement = null;
      }

      nodeDisplayOrder.removeWhere((node) {
        if (!graph.allNodes.contains(node)) {
          nodeWidgets.remove(node);
          selectedElements.remove(node);
          return true;
        } else {
          return false;
        }
      });

      edgeDisplayOrder.removeWhere((edge) {
        if (!graph.edges.contains(edge)) {
          edgeWidgets.remove(edge);
          selectedElements.remove(edge);
          return true;
        } else {
          return false;
        }
      });

      var newNodes = graph.allNodes
          .where((node) => !nodeDisplayOrder.contains(node))
          .toList();
      var newEdges = graph.edges
          .where((edge) => !edgeDisplayOrder.contains(edge))
          .toList();

      // Insert new elements in under currently selected elements
      for (var i = nodeDisplayOrder.length - 1; i >= 0; i--) {
        if (selectedElements.contains(nodeDisplayOrder[i])) {
          nodeDisplayOrder.insertAll(i + 1, newNodes);
          break;
        }
      }

      for (var i = edgeDisplayOrder.length - 1; i >= 0; i--) {
        if (selectedElements.contains(edgeDisplayOrder[i])) {
          edgeDisplayOrder.insertAll(i + 1, newEdges);
          break;
        }
      }

      if (hasBeenInitiated) {
        setState(() {
          for (var newNode in newNodes) {
            nodeWidgets[newNode] = NodeWidget(node: newNode);
          }

          for (var newEdge in newEdges) {
            edgeWidgets[newEdge] = EdgeWidget(edge: newEdge);
          }
        });
      }
    }

    if (hasBeenInitiated) {
      for (var elementChangeNotifier in [
        ...nodeWidgets.values.map((widget) => widget.nodeChangeNotifier),
        ...edgeWidgets.values.map((widget) => widget.edgeChangeNotifier),
        graphOverlay.changeNotifier,
      ]) {
        elementChangeNotifier.newSnapshot();
      }
    }

    hasBeenInitiated = true;
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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
  final List<NodeElement> nodeDisplayOrder;
  final List<Edge> edgeDisplayOrder;

  int _allElementsHash;

  GraphWidgetPersistentState(this.graph)
    : controller = TransformationController(),
      nodeDisplayOrder = List.from(graph.allNodes),
      edgeDisplayOrder = List.from(graph.edges),
      _allElementsHash = graph.allElementsHash;
}

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
