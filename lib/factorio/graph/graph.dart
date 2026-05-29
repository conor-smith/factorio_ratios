import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

part 'base_graph.dart';
part 'edge.dart';
part 'event_history.dart';
part 'node.dart';

/// This object represents the entire base, and is the single source of truth for the app.
/// Stores all event history, default recipes, and any global data.
/// Every [PlanetBaseGraph] object will have reference to this object.
///
/// Creates a single [PlanetBaseGraph] to act as the [rootGraph].
/// As a planetBase is a production line, a [ProdLineNode] a [PlanetBaseGraph] object.
/// Every [PlanetBaseGraph] is owned by a single node.
/// This ultimately creates a tree like structure where each graph can own several
/// "child" graphs (via it's nodes), and each graph is owned by only one parent.
/// The only exception to this being [rootGraph], which consequently cannot have
/// input or output nodes.
///
/// All state change operations must happen through this object.
class FactorioBase extends EventNotifier {
  final FactorioDatabase factorioDb;
  final _EventHistory _history;

  final List<InGameMachine> sortedMachines;
  final Map<Surface, SurfaceProperties> _surfaceProperties;
  late final PlanetBaseGraph rootGraph;

  /// The graph to display in the UI
  late PlanetBaseGraph _activeGraph;

  final Set<ProdLineNode> _selectedNodes = {};
  final Set<DirectedEdge> _selectedEdges = {};

  PlanetBaseGraph get activeGraph => _activeGraph;

  late final Set<ProdLineNode> selectedNodes = UnmodifiableSetView(
    _selectedNodes,
  );
  late final Set<DirectedEdge> selectedEdges = UnmodifiableSetView(
    _selectedEdges,
  );

  FactorioBase(this.factorioDb)
    : _history = _EventHistory(20),
      _surfaceProperties = factorioDb.surfaceMap.map(
        (name, surface) => MapEntry(
          surface,
          SurfaceProperties._(
            defaultRecipes: surface.recipes.where((recipe) => recipe.isSimple),
            resources: surface.resourceItems.map((item) => InGameItem(item)),
            availableSolidFuels: surface.resourceItems
                .whereType<SolidItem>()
                .where((solidItem) => (solidItem.fuelValue ?? 0) > 0)
                .map((solidItem) => InGameSolidItem(solidItem)),
          ),
        ),
      ),
      sortedMachines = List.unmodifiable(
        factorioDb.craftingMachineMap.values
            .map((machine) => InGameMachine(machine))
            .toList()
          ..sort(
            (machine1, machine2) =>
                machine2.craftingSpeed.compareTo(machine1.craftingSpeed),
          ),
      ) {
    var nauvis = factorioDb.surfaceMap['nauvis']!;

    // TODO - Top graph should have no surface
    rootGraph = PlanetBaseGraph._root(
      globalData: this,
      surface: nauvis,
      surfaceProperties: _surfaceProperties[nauvis]!,
    );
    _activeGraph = rootGraph;
  }

  void changeActiveGraph(PlanetBaseGraph graph) {
    // TODO - ensure this new graph is valid
    _activeGraph = graph;

    _selectedNodes.clear();
    _selectedEdges.clear();
  }

  void addNodeToSelected(ProdLineNode node) {
    if (node.parentGraph != activeGraph) {
      throw GraphException('Cannot select node not in active graph');
    }

    if (!_selectedNodes.contains(node)) {
      var newEdgesBetweenNodes = node._parents
          .where((parentEdge) => _selectedNodes.contains(parentEdge.parent))
          .followedBy(
            node._children.where(
              (childEdge) => _selectedNodes.contains(childEdge.child),
            ),
          )
          .toList();

      _selectedEdges.addAll(newEdgesBetweenNodes);
      for (var edge in newEdgesBetweenNodes) {
        edge.notifyListeners(EdgeEvent.selectToggle(edge));
      }

      _selectedNodes.add(node);
      node.notifyListeners(NodeEvent.selectToggle(node));
    }
  }

  void deselectNode(ProdLineNode node) {
    if (_selectedNodes.contains(node)) {
      if (_selectedEdges.isNotEmpty) {
        var nodeEdges = [...node._children, ...node._parents];
        _selectedEdges.removeAll(nodeEdges);

        for (var edge in nodeEdges) {
          edge.notifyListeners(EdgeEvent.selectToggle(edge));
        }
      }

      _selectedNodes.remove(node);
      node.notifyListeners(NodeEvent.selectToggle(node));
    }
  }

  void selectEdge(DirectedEdge edge) {
    if (!_selectedEdges.contains(edge)) {
      _selectedEdges.add(edge);
      edge.notifyListeners(EdgeEvent.selectToggle(edge));
    }
  }

  void deselectEdge(DirectedEdge edge) {
    if (_selectedEdges.contains(edge)) {
      _selectedEdges.remove(edge);
      edge.notifyListeners(EdgeEvent.selectToggle(edge));
    }
  }

  void clearSelection() {
    for (var node in _selectedNodes) {
      node.notifyListeners(NodeEvent.selectToggle(node));
    }
    _selectedNodes.clear();

    for (var edge in _selectedEdges) {
      edge.notifyListeners(EdgeEvent.selectToggle(edge));
    }
    _selectedEdges.clear();
  }

  GeometryOperation createDragGeometryOperation() {
    var edgesBetweenNodes = _activeGraph._edges
        .where((edge) => _selectedNodes.containsAll([edge.parent, edge.child]))
        .toSet();

    return GeometryOperation.dragOperation(_selectedNodes, edgesBetweenNodes);
  }

  void finishGeometryOperation(GeometryOperation operation) {
    // TODO - verify correct graph
    activeGraph.finishGeometryOperation(operation);
  }

  void activeGraphAddConsumerNodeAndTree(InGameItem item) {
    activeGraph.addConsumerNodeAndTree(item);
  }

  void activeGraphClearAllNodes() {
    activeGraph.clearAllNodes();
  }
}

class GraphException extends ProductionLineException {
  const GraphException(super.message);

  @override
  String toString() => 'GraphException: $message';
}

class SurfaceProperties {
  final List<Recipe> defaultRecipes;
  final List<InGameItem> resources;
  final List<InGameSolidItem> availableSolidFuels;
  // TODO - Liquid fuels

  SurfaceProperties._({
    required Iterable<Recipe> defaultRecipes,
    required Iterable<InGameItem> resources,
    required Iterable<InGameSolidItem> availableSolidFuels,
  }) : defaultRecipes = List.unmodifiable(defaultRecipes),
       resources = List.unmodifiable(resources),
       availableSolidFuels = List.unmodifiable(availableSolidFuels);
}
