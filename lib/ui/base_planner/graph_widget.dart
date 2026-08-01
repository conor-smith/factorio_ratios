import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_model.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:factorio_ratios/ui/factorio_icon_menu.dart';
import 'package:factorio_ratios/ui/icon_widgets.dart';
import 'package:flutter/material.dart' hide Icon;

class GraphOverlay extends StatelessWidget {
  const GraphOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    var model = BasePlannerModel.of(
      context,
      BasePlannerModelAspect(DependencyType.graphOverlay),
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black)),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.all(5),
                child: IconWidgetCache.get(model.activeGraphIcon),
              ),
              Text(model.activeGraphName),
            ],
          ),
        ),
      ],
    );
  }
}

class GraphWindow extends StatelessWidget {
  const GraphWindow({super.key});

  void createContextMenu(
    BuildContext context,
    Graph activeGraph,
    Offset screenPosition,
    Offset graphPosition,
  ) {
    pushOverlayMenu(
      context,
      ContextMenu(
        screenLocation: screenPosition,
        options: [
          MenuOption(
            text: 'Create consumer node',
            operation: (ctx) =>
                createConsumerMenu(ctx, graphPosition, activeGraph),
          ),
          MenuOption(
            text: 'Build full graph',
            operation: (_) => activeGraph.fulfillAllNodeIo(),
          ),
        ],
      ),
    );
  }

  void createConsumerMenu(
    BuildContext context,
    Offset graphPosition,
    Graph activeGraph,
  ) {
    pushOverlayMenu(
      context,
      Center(
        child: FactorioIconMenuWidget<Item>(
          itemGroups: activeGraph.basePlanner.validConsumerNodeItems,
          onSelected: (item) {
            activeGraph.addNode(
              nodeType: NodeType.consumer,
              productionLine: MagicLine.singleItemConsumer(InGameItem(item)),
              initialPosition: graphPosition,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var model = BasePlannerModel.of(
      context,
      BasePlannerModelAspect(DependencyType.graphView),
    );

    List<NodeElement> unselectedNodes;
    List<NodeElement> selectedNodes;
    List<Edge> unselectedEdges;
    List<Edge> selectedEdges;

    if (model.selectedElements.isEmpty) {
      unselectedNodes = model.orderedNodes;
      unselectedEdges = model.orderedEdges;
      selectedNodes = const [];
      selectedEdges = const [];
    } else {
      unselectedNodes = [];
      selectedNodes = [];
      for (var node in model.orderedNodes) {
        if (!model.selectedElements.contains(node)) {
          unselectedNodes.add(node);
        } else {
          selectedNodes.add(node);
        }
      }

      unselectedEdges = [];
      selectedEdges = [];
      for (var edge in model.orderedEdges) {
        if (!model.selectedElements.contains(edge)) {
          unselectedEdges.add(edge);
        } else {
          selectedEdges.add(edge);
        }
      }
    }

    return InteractiveViewer(
      panEnabled: model.allowTransformation,
      scaleEnabled: model.allowTransformation,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapUp: (details) {
              if (!isShiftKeyHeld(context)) {
                createContextMenu(
                  context,
                  model.activeGraph,
                  details.globalPosition,
                  details.localPosition,
                );
              }
            },
          ),
          ...unselectedEdges.map(
            (edge) => EdgeWidget(key: BasePlannerElementKey(edge), edge: edge),
          ),
          ...unselectedNodes.map(
            (node) => NodeWidget(key: BasePlannerElementKey(node), node: node),
          ),
          ...selectedEdges.map(
            (edge) => EdgeWidget(key: BasePlannerElementKey(edge), edge: edge),
          ),
          ...selectedNodes.map(
            (node) => NodeWidget(key: BasePlannerElementKey(node), node: node),
          ),
        ],
      ),
    );
  }
}

class ContextMenu extends StatelessWidget {
  final Offset screenLocation;
  final List<MenuOption> options;

  const ContextMenu({
    super.key,
    required this.screenLocation,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: screenLocation.dy,
      left: screenLocation.dx,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options,
        ),
      ),
    );
  }
}

class MenuOption extends StatelessWidget {
  final String text;
  final Function(BuildContext context) operation;

  const MenuOption({super.key, required this.text, required this.operation});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () => operation(context), child: Text(text));
  }
}

class BasePlannerElementKey extends LocalKey {
  final BasePlannerElement element;

  const BasePlannerElementKey(this.element);

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is BasePlannerElementKey && other.element == element);

  @override
  int get hashCode => element.hashCode;
}
