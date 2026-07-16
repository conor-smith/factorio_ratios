import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:factorio_ratios/ui/icon_widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BasePlannerWidget extends StatefulWidget {
  final BasePlanner basePlanner;

  final IconWidgetCache _cache = IconWidgetCache();

  BasePlannerWidget({super.key, required this.basePlanner});

  static IconWidgetCache getWidgetCache(BuildContext context) =>
      context.findAncestorWidgetOfExactType<BasePlannerWidget>()!._cache;

  @override
  State<BasePlannerWidget> createState() => _BasePlannerWidgetState();
}

class _BasePlannerWidgetState extends State<BasePlannerWidget> {
  BasePlanner get basePlanner => widget.basePlanner;
  ActiveMenu activeMenu = ActiveMenu.noMenu;

  int? pointerDownButton;

  Offset? contextMenuPosition;
  late final BasePlannerContextWidget contextMenu = BasePlannerContextWidget(
    options: {
      'Create consumer node': () =>
          setState(() => activeMenu = ActiveMenu.consumerMenu),
    },
  );

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

  @override
  void dispose() {
    super.dispose();

    basePlanner.removeListener(this);
  }

  void addConsumerNodeToActiveGraph(Item item) => setState(() {
    basePlanner.activeGraph.addConsumerNodeAndTree(InGameItem(item));
    activeMenu = ActiveMenu.noMenu;
  });

  void onEvent(BasePlannerEvent event) {
    for (var removedGraph in event.removedGraphs) {
      graphWidgets.remove(removedGraph);
    }

    if (event.newActiveGraph) {
      setState(() => activeMenu = ActiveMenu.noMenu);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Listener(
        onPointerDown: (event) {
          pointerDownButton = event.buttons;
        },
        onPointerCancel: (event) {
          pointerDownButton = null;
          activeMenu = ActiveMenu.noMenu;
        },
        onPointerUp: (event) {
          if (pointerDownButton == kSecondaryButton) {
            setState(() {
              if (activeMenu == ActiveMenu.noMenu) {
                activeMenu = ActiveMenu.contextMenu;
                contextMenuPosition = event.localPosition;
              } else {
                activeMenu = ActiveMenu.noMenu;
                contextMenuPosition = null;
              }
            });
          } else if (activeMenu != ActiveMenu.noMenu) {
            setState(() {
              activeMenu = ActiveMenu.noMenu;
              contextMenuPosition = null;
            });
          }

          pointerDownButton = null;
        },
        behavior: HitTestBehavior.opaque,
      ),
      graphWidgets.putIfAbsent(
        basePlanner.activeGraph,
        () => GraphWidget(graph: basePlanner.activeGraph),
      ),
      Positioned(
        left: 20,
        top: 20,
        child: TextButton(
          onPressed: () {
            if (activeMenu == ActiveMenu.noMenu) {
              basePlanner.activeGraph.clear();
            }
          },
          child: const Text('x'),
        ),
      ),
    ];

    switch (activeMenu) {
      case ActiveMenu.contextMenu:
        children.add(
          Positioned(
            top: contextMenuPosition!.dy,
            left: contextMenuPosition!.dx,
            child: contextMenu,
          ),
        );

      case ActiveMenu.consumerMenu:
        children.add(consumerMenu);

      case ActiveMenu.noMenu:
        break;
    }

    return Stack(fit: StackFit.expand, children: children);
  }
}

class BasePlannerContextWidget extends StatelessWidget {
  final Map<String, Function()> options;

  const BasePlannerContextWidget({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        children: options.entries
            .map(
              (entry) =>
                  TextButton(onPressed: entry.value, child: Text(entry.key)),
            )
            .toList(),
      ),
    );
  }
}

enum ActiveMenu { noMenu, contextMenu, consumerMenu }
