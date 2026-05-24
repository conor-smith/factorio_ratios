import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:factorio_ratios/ui/graph/graph_widget.dart';
import 'package:flutter/material.dart';

class FactorioBaseWidget extends StatefulWidget {
  final FactorioBase base;

  final OverlayStateNotifier updateNotifier;

  FactorioBaseWidget({super.key, required this.base})
    : updateNotifier = OverlayStateNotifier(activeGraph: base.rootGraph);

  static OverlayStateNotifier getOverlayNotifier(BuildContext context) =>
      context
          .findAncestorWidgetOfExactType<FactorioBaseWidget>()!
          .updateNotifier;

  @override
  State<FactorioBaseWidget> createState() => _FactorioBaseWidgetState();
}

class _FactorioBaseWidgetState extends State<FactorioBaseWidget> {
  final Map<PlanetBaseGraph, GraphWidget> graphWidgets = {};

  PlanetBaseGraph get activeGraph => widget.updateNotifier._activeGraph;
  ProdLineNode? get activeNode => widget.updateNotifier._activeNode;
  bool get selectionMenuActive => widget.updateNotifier._selectionMenuActive;
  FactorioDatabase get factorioDb => widget.base.factorioDb;

  late final FactorioGroupMenuWidget<Item> menuWidget = FactorioGroupMenuWidget(
    items: factorioDb.itemMap.values.where((item) => !item.hidden).toList(),
    onSelected: (item) => addConsumerToActiveGraph(item),
  );

  void addConsumerToActiveGraph(Item item) {
    widget.updateNotifier.toggleSelectionMenu(false);

    activeGraph.addConsumerNodeAndTree(InGameItem(item));
  }

  @override
  void initState() {
    super.initState();

    widget.updateNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
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

class OverlayStateNotifier extends ChangeNotifier {
  PlanetBaseGraph _activeGraph;
  ProdLineNode? _activeNode;
  bool _selectionMenuActive;

  OverlayStateNotifier({
    required PlanetBaseGraph activeGraph,
    ProdLineNode? activeNode,
    bool selectionMenuActive = false,
  }) : _selectionMenuActive = selectionMenuActive,
       _activeNode = activeNode,
       _activeGraph = activeGraph;

  void toggleSelectionMenu([bool? explicitValue]) {
    _selectionMenuActive = explicitValue ?? !_selectionMenuActive;
    notifyListeners();
  }

  void updateActiveGraph(PlanetBaseGraph newGraph) {
    if (_activeGraph != newGraph) {
      _selectionMenuActive = false;
      _activeNode = null;
      _activeGraph = newGraph;
      notifyListeners();
    }
  }

  void updateActiveNode(ProdLineNode? newNode) {
    if (newNode != _activeNode) {
      _activeNode = newNode;
      notifyListeners();
    }
  }
}
