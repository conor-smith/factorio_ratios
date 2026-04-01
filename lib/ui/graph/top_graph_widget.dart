import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:factorio_ratios/ui/graph/graph_widget.dart';
import 'package:flutter/material.dart';

class TopGraphWidget extends StatefulWidget {
  final FactorioDatabase db;
  final BaseGraph topGraph;

  final List<CraftingMachine> sortedMachines;
  final Map<Surface, SurfaceProperties> surfacePropertiesMap;

  const TopGraphWidget({
    super.key,
    required this.db,
    required this.topGraph,
    required this.sortedMachines,
    required this.surfacePropertiesMap,
  });

  factory TopGraphWidget.createFromDb({
    Key? key,
    required FactorioDatabase db,
  }) {
    // TODO - Top graph should have no surface
    BaseGraph topGraph = BaseGraph(surface: db.surfaceMap['nauvis']!);

    List<CraftingMachine> sortedMachines = db.craftingMachineMap.values
        .toList();
    sortedMachines.sort(
      (machine1, machine2) =>
          machine1.craftingSpeed.compareTo(machine2.craftingSpeed),
    );

    Map<Surface, SurfaceProperties> surfacePropertiesMap = {};
    for (var surface in db.surfaceMap.values) {
      List<Recipe> defaultRecipes = surface.recipes
          .where(
            (recipe) =>
                !recipe.categories.contains('recycling') &&
                recipe.itemIo.entries
                        .where((entry) => entry.value > 0)
                        .length ==
                    1,
          )
          .toList();

      List<ItemData> resources = surface.resourceItems
          .map((item) => ItemData(item))
          .toList();
      List<ItemData> fuels = surface.resourceItems
          .whereType<SolidItem>()
          .where((item) => item.fuelValue != null)
          .map((item) => ItemData(item))
          .toList();
      fuels.sort(
        (fuel1, fuel2) =>
            fuel1.item.fuelValue!.compareTo(fuel2.item.fuelValue!),
      );

      surfacePropertiesMap[surface] = SurfaceProperties(
        defaultRecipes: List.unmodifiable(defaultRecipes),
        resources: List.unmodifiable(resources),
        availableFuels: List.unmodifiable(fuels),
      );
    }

    return TopGraphWidget(
      key: key,
      db: db,
      topGraph: topGraph,
      sortedMachines: sortedMachines,
      surfacePropertiesMap: surfacePropertiesMap,
    );
  }

  @override
  State<TopGraphWidget> createState() => _TopGraphWidgetState();
}

class _TopGraphWidgetState extends State<TopGraphWidget> {
  late BaseGraph activeGraph = widget.topGraph;

  final Map<BaseGraph, GraphWidget> graphWidgets = {};

  bool selectionMenuActive = false;
  late final FactorioGroupMenuWidget<Item> menuWidget = FactorioGroupMenuWidget(
    items: widget.db.itemMap.values.where((item) => !item.hidden).toList(),
    onSelected: (item) => setState(() {
      selectionMenuActive = false;

      SurfaceProperties surfaceProperties;
      if (activeGraph.surface != null) {
        surfaceProperties = widget.surfacePropertiesMap[activeGraph.surface]!;
      } else {
        surfaceProperties = SurfaceProperties.empty;
      }

      activeGraph.addConsumerNodeAndTree(
        ItemData(item),
        widget.sortedMachines,
        surfaceProperties.defaultRecipes,
        surfaceProperties.resources,
        surfaceProperties.availableFuels,
        updateListeners: true,
      );
    }),
  );

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() {
          selectionMenuActive = !selectionMenuActive;
        }),
      ),
      graphWidgets.putIfAbsent(
        activeGraph,
        () => GraphWidget(graph: activeGraph),
      ),
    ];
    if (selectionMenuActive) {
      children.add(Center(child: menuWidget));
    }

    return Stack(children: children);
  }
}

class SurfaceProperties {
  final List<Recipe> defaultRecipes;
  final List<ItemData> resources;
  final List<ItemData> availableFuels;

  const SurfaceProperties({
    this.defaultRecipes = const [],
    this.availableFuels = const [],
    this.resources = const [],
  });

  static const SurfaceProperties empty = SurfaceProperties();
}
