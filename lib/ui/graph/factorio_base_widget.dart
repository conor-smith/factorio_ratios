import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:factorio_ratios/ui/graph/graph_widget.dart';
import 'package:flutter/material.dart';

class FactorioBaseWidget extends StatefulWidget {
  final FactorioBase base;

  const FactorioBaseWidget({super.key, required this.base});

  @override
  State<FactorioBaseWidget> createState() => _FactorioBaseWidgetState();
}

class _FactorioBaseWidgetState extends State<FactorioBaseWidget> {
  final Map<PlanetBaseGraph, GraphWidget> graphWidgets = {};
  late final GraphChangeNotifier graphChangeNotifier = GraphChangeNotifier(
    activeGraph: widget.base.rootGraph,
  );

  PlanetBaseGraph get activeGraph => graphChangeNotifier._activeGraph;
  ProdLineNode? get activeNode => graphChangeNotifier._activeNode;
  bool get selectionMenuActive => graphChangeNotifier._selectionMenuActive;
  FactorioDatabase get factorioDb => widget.base.factorioDb;

  late final FactorioGroupMenuWidget<Item> menuWidget = FactorioGroupMenuWidget(
    items: factorioDb.itemMap.values.where((item) => !item.hidden).toList(),
    onSelected: (item) => addConsumerToActiveGraph(item),
  );

  void addConsumerToActiveGraph(Item item) {
    graphChangeNotifier.toggleSelectionMenu(false);

    activeGraph.addConsumerNodeAndTree(InGameItem(item));
  }

  @override
  void initState() {
    super.initState();

    // TODO - Add some actual logic
    graphChangeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      graphWidgets.putIfAbsent(
        activeGraph,
        () => GraphWidget(
          graph: activeGraph,
          graphChangeNotifier: graphChangeNotifier,
        ),
      ),
    ];

    if (selectionMenuActive) {
      children.add(Center(child: menuWidget));
    }

    return Stack(children: children);
  }
}

class GraphChangeNotifier extends ChangeNotifier {
  PlanetBaseGraph _activeGraph;
  ProdLineNode? _activeNode;
  bool _selectionMenuActive;
  final Set<ProdLineNode> _selectedNodes = {};
  final Set<DirectedEdge> _selectedEdges = {};

  GraphChangeNotifier({
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

      for (var node in _selectedNodes) {
        node.notifyListeners(NodeEvent.selectToggle(node, false));
      }
      _selectedNodes.clear();

      for (var edge in _activeGraph.edges) {
        edge.notifyListeners(EdgeEvent.selectToggle(edge, false));
      }
      _selectedEdges.clear();

      notifyListeners();
    }
  }

  void updateActiveNode(ProdLineNode? newNode) {
    if (newNode != _activeNode) {
      _activeNode = newNode;
      notifyListeners();
    }
  }

  // TODO - Listen to keyboard for shift key
  void selectNodes(List<ProdLineNode> nodes) {
    for (var selectedNode in nodes) {
      selectNode(selectedNode);
    }
  }

  void selectNode(ProdLineNode selectedNode) {
    // Add all edges between selected nodes
    var newSelectedEdges = selectedNode.parents
        .where((parentEdge) => _selectedNodes.contains(parentEdge.parent))
        .followedBy(
          selectedNode.children.where(
            (childEdge) => _selectedNodes.contains(childEdge.child),
          ),
        )
        .toList();

    _selectedEdges.addAll(newSelectedEdges);
    _selectedNodes.add(selectedNode);

    for (var edge in newSelectedEdges) {
      edge.notifyListeners(EdgeEvent.selectToggle(edge, true));
    }
    selectedNode.notifyListeners(NodeEvent.selectToggle(selectedNode, true));
  }

  GeometryOperation drag() {
    return _activeGraph.beginDragOperation(_selectedNodes, _selectedEdges);
  }

  void finishGeometryOperation(GeometryOperation operation) {
    _activeGraph.finishGeometryOperation(operation);
  }
}
