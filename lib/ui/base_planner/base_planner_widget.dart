import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:factorio_ratios/ui/icon_widgets.dart';
import 'package:flutter/material.dart';

class BasePlannerWidget extends StatefulWidget {
  final BasePlanner basePlanner;

  BasePlannerWidget({super.key, required this.basePlanner}) {
    basePlanner.activeGraph.addConsumerNodeAndTree(
      InGameItem(basePlanner.db.itemMap['production-science-pack']!),
    );
  }

  static IconWidgetCache getWidgetCache(BuildContext context) =>
      context.findAncestorStateOfType<_BasePlannerWidgetState>()?.cache ??
      IconWidgetCache();

  @override
  State<BasePlannerWidget> createState() => _BasePlannerWidgetState();
}

class _BasePlannerWidgetState extends State<BasePlannerWidget> {
  BasePlanner get basePlanner => widget.basePlanner;
  bool consumerMenuActive = false;

  final IconWidgetCache cache = IconWidgetCache();
  final Map<Graph, GraphWidget> graphWidgets = {};
  late final FactorioGroupMenuWidget<Item> consumerMenu =
      FactorioGroupMenuWidget(
        items: widget.basePlanner.db.itemMap.values.where(
          (item) => item.producedBy.isNotEmpty,
        ),
        onSelected: addConsumerNodeToActiveGraph,
      );

  @override
  void initState() {
    super.initState();

    basePlanner.addListener(this, onEvent);
  }

  void addConsumerNodeToActiveGraph(Item item) {
    basePlanner.activeGraph.addConsumerNodeAndTree(InGameItem(item));
  }

  void onEvent(BasePlannerEvent event) {
    for (var removedGraph in event.removedGraphs) {
      graphWidgets.remove(removedGraph);
    }

    if (event.newActiveGraph) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      graphWidgets.putIfAbsent(
        basePlanner.activeGraph,
        () => GraphWidget(graph: basePlanner.activeGraph),
      ),
    ];

    if (consumerMenuActive) {
      children.add(Center(child: consumerMenu));
    }

    return Stack(children: children);
  }
}
