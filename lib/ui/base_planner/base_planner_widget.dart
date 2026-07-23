import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/factorio_icon_menu.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:factorio_ratios/ui/icon_widgets.dart';
import 'package:flutter/material.dart';

class BasePlannerWidget extends StatefulWidget {
  final BasePlanner basePlanner;

  const BasePlannerWidget({super.key, required this.basePlanner});

  @override
  State<BasePlannerWidget> createState() => _BasePlannerWidgetState();
}

class _BasePlannerWidgetState extends State<BasePlannerWidget> {
  late final BasePlannerGlobalState _globalState = BasePlannerGlobalState._(
    this,
  );
  final IconWidgetCache iconCache = IconWidgetCache();

  late final BasePlannerContextWidget contextMenu = BasePlannerContextWidget(
    options: {
      'Create consumer node': () =>
          setState(() => activeMenu = ActiveMenu.consumerMenu),
    },
  );
  late final FactorioIconMenuWidget<Item> consumerMenu = FactorioIconMenuWidget(
    itemGroups: SortedItemGroups(
      basePlanner.db.itemMap.values.where((item) => item.producedBy.isNotEmpty),
    ),
    onSelected: addConsumerNodeToActiveGraph,
  );

  final Map<Graph, GraphWidget> graphWidgets = {};

  ActiveMenu activeMenu = ActiveMenu.noMenu;
  Offset? contextMenuPosition;

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

  BasePlanner get basePlanner => widget.basePlanner;

  void toggleContextMenu(Offset globalPosition) {
    var localPosition = Offset(globalPosition.dx, globalPosition.dy - 74);

    switch (activeMenu) {
      case ActiveMenu.noMenu:
        setState(() {
          activeMenu = ActiveMenu.contextMenu;
          contextMenuPosition = localPosition;
        });

      case ActiveMenu.contextMenu:
        setState(() {
          activeMenu = ActiveMenu.noMenu;
          contextMenuPosition = null;
        });

      case ActiveMenu.consumerMenu:
        break;
    }
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

    Widget? icon;
    if (basePlanner.activeGraph.icon != null) {
      icon = Padding(
        padding: EdgeInsetsGeometry.all(5),
        child: iconCache.get(basePlanner.activeGraph.icon!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: icon,
        toolbarHeight: 74,
        title: Text(basePlanner.activeGraph.name),
      ),
      body: Stack(fit: StackFit.expand, children: children),
    );
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

class BasePlannerGlobalState {
  final _BasePlannerWidgetState _widgetState;

  BasePlannerGlobalState._(this._widgetState);

  static BasePlannerGlobalState of(BuildContext context) {
    var ancestorState = context
        .findAncestorStateOfType<_BasePlannerWidgetState>();

    if (ancestorState != null) {
      return ancestorState._globalState;
    } else {
      throw const BasePlannerException('BasePlanner widget not active');
    }
  }

  void toggleContextMenu(Offset globalPosition) =>
      _widgetState.toggleContextMenu(globalPosition);

  IconWidgetCache get iconCache => _widgetState.iconCache;
}

enum ActiveMenu { noMenu, contextMenu, consumerMenu }
