import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/change_tracker/change_trackers.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/utility/json.dart';
import 'package:factorio_ratios/utility/builder.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'graph_state.dart';

/// Represents a graph of [NodeElement]s connected by [Edge]s.
class Graph extends NodeElement<GraphStateImpl, GraphEvent> {
  // TODO - Graph preferred layout
  final Surface? surface;
  @override
  late final Graph parentGraph;
  bool get isRoot => this == parentGraph;

  final Set<BasePlannerElement> _selectedElements = {};
  late final Set<BasePlannerElement> selectedElements = UnmodifiableSetView(
    _selectedElements,
  );

  final SurfaceProperties _surfaceProperties;

  GraphStateImpl _internalState;
  GraphState get _state =>
      basePlanner.snapshotBuilder?.graphTrackers[this]?.state ?? _internalState;

  String get name => _state.name;
  Icon? get icon => _state.icon;
  @override
  NodeGeometryImpl get geometry => _state.geometry;
  @override
  Map<InGameItem, Set<Edge>> get parents => _state.parents;
  @override
  Map<InGameItem, Set<Edge>> get children => _state.children;
  @override
  Set<Edge> get allParents => _state.allParents;
  @override
  Set<Edge> get allChildren => _state.allChildren;

  Set<Graph> get graphNodes => _state.graphNodes;
  Set<ProdLineNode> get prodLineNodes => _state.prodLineNodes;
  Map<InGameItem, ProdLineNode> get outputNodes => _state.outputNodes;
  Map<InGameItem, ProdLineNode> get inputNodes => _state.inputNodes;
  Set<NodeElement> get allNodes => _state.allNodes;
  GraphLayout get layout => _state.layout;
  LayoutOrientation get orientation => _state.orientation;
  Set<Edge> get edges => _state.edges;
  @override
  Set<InGameItem> get inputItems => _state.inputItems;
  @override
  Set<InGameItem> get outputItems => _state.outputItems;

  @override
  ProductionLineType get productionLineType => ProductionLineType.graph;
  @override
  NodeType get nodeType => NodeType.productionLine;
  @override
  ItemIoImpl? get internalConstraints => null;

  @override
  GraphIo get ioData => _state.ioData;

  @override
  ItemIoImpl get edgeConstraints => ioData.constraints;
  @override
  ItemIoImpl get unusedIo => _state.unusedIo;
  @override
  ItemIoImpl get ioRatios => _state.ioRatios;

  Graph.addToBasePlanner(
    super.basePlanner, {
    required this.parentGraph,
    this.surface,
    String name = 'graph',
    Icon? icon,
    NodeGeometryImpl geometry = NodeGeometryImpl.uninitialised,
  }) : _internalState = GraphStateImpl.uninitialised,
       _surfaceProperties =
           basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty {
    GraphChangeTracker.newGraph(
      this,
      _internalState,
      GraphStateBuilder.initial(icon),
    );
  }

  Graph.rootGraph(super.basePlanner, GraphStateImpl state, [this.surface])
    : _internalState = state,
      _surfaceProperties =
          basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty {
    parentGraph = this;
  }

  void addToSelected(BasePlannerElement element) {
    _selectedElements.add(element);
    element.notifyListenersOfUpdate();
  }

  void removeFromSelected(BasePlannerElement element) {
    _selectedElements.remove(element);
    element.notifyListenersOfUpdate();
  }

  void clearSelected(bool notifyListeners) {
    if (notifyListeners) {
      List<BasePlannerElement> deselectedElements = List.from(
        _selectedElements,
      );
      _selectedElements.clear();

      for (var element in deselectedElements) {
        element.notifyListenersOfUpdate();
      }
    } else {
      _selectedElements.clear();
    }
  }

  @override
  void updateState(GraphStateImpl newState) {
    basePlanner.throwIfMutationNotPermitted();
    if (_selectedElements.isNotEmpty) {
      Set<BasePlannerElement> allElements = {
        ...newState.allNodes,
        ...newState.edges,
      };

      _selectedElements.removeWhere(
        (element) => !allElements.contains(element),
      );
    }

    _internalState = newState;
  }

  @override
  GraphChangeTracker getChangeTracker() => basePlanner
      .getSnapshotBuilderOrThrow()
      .getGraphChangeTracker(this, _internalState);

  @override
  GraphStateBuilder getStateBuilder() => getChangeTracker().stateBuilder;

  @override
  ProdLineNode getOutputItemNode(InGameItem item) {
    var outputNode = outputNodes[item];

    if (outputNode != null) {
      return outputNode;
    } else {
      throw GraphException(
        'Graph $this does not have an output node for item $item',
      );
    }
  }

  @override
  ProdLineNode getInputItemNode(InGameItem item) {
    var inputNode = inputNodes[item];

    if (inputNode != null) {
      return inputNode;
    } else {
      throw GraphException(
        'Graph $this does not have an input node for item $item',
      );
    }
  }

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometry geometry) =>
      notifyListeners(GraphEvent.geometryOp(geometry));

  @override
  void notifyListenersOfUpdate() {
    notifyListeners(const GraphEvent());
  }

  /// Clears all nodes except IO nodes
  void clear() {
    basePlanner.buildNextSnapshot(() {
      getChangeTracker().removeAllNodesExceptIo();
    });
  }

  void addNode({
    required NodeType nodeType,
    required ProductionLine productionLine,
    required Offset initialPosition,
    ItemIoImpl? internalConstraints,
  }) {
    basePlanner.buildNextSnapshot(() {
      NodeGeometryImpl initialGeometry;
      if (layout == GraphLayout.custom) {
        initialGeometry = NodeGeometryImpl(
          Rect.fromCenter(
            center: initialPosition,
            width: NodeGeometryImpl.defaultWidth,
            height: NodeGeometryImpl.defaultHeight,
          ),
        );
      } else {
        initialGeometry = NodeGeometryImpl.uninitialised;
      }

      ProdLineNode.addToBasePlanner(
        basePlanner,
        parentGraph: this,
        nodeType: nodeType,
        productionLine: productionLine,
        internalConstraints: internalConstraints,
        initialGeometry: initialGeometry,
      );
    });
  }

  void addConsumerNodeAndTree(InGameItem item) {
    if (surface == null) {
      throw const GraphException(
        'Cannot build node tree of graph with no surface',
      );
    }

    // Check if consumer node already exists
    if (prodLineNodes.any(
      (node) =>
          node.nodeType == NodeType.consumer && node.inputItems.contains(item),
    )) {
      return;
    }

    basePlanner.buildNextSnapshot(() {
      var consumerNode = ProdLineNode.addToBasePlanner(
        basePlanner,
        parentGraph: this,
        nodeType: NodeType.consumer,
        productionLine: MagicLine.singleItemConsumer(item),
      );

      _createNodeTree(consumerNode);

      layoutNodes();
    });
  }

  void layoutNodes({
    GraphLayout? newLayout,
    LayoutOrientation? newOrientation,
  }) {
    basePlanner.buildNextSnapshot(() {
      if (newLayout != null && newLayout != layout) {
        getStateBuilder().updateLayout(newLayout);
      }

      if (newOrientation != null && newOrientation != orientation) {
        getStateBuilder().updateOrientation(newOrientation);
      }

      if (allNodes.isEmpty) {
        return;
      }

      switch (layout) {
        case GraphLayout.table:
          _tableLayout();

        case GraphLayout.custom:
          break;
      }
    });
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  void _createNodeTree(NodeElement startNode) {
    // Ignore items that already have an input edge
    var requiredInputs = startNode.inputItems.difference(
      startNode.allChildren.map((edge) => edge.item).toSet(),
    );

    for (var input in requiredInputs) {
      var nextNode =
          getChangeTracker().cachedNodeOutputIndex[input]?.firstOrNull;

      if (nextNode == null) {
        nextNode =
            _createResourceNode(input) ??
            _createRecipeNode(input) ??
            _createMagicResourceNode(input);

        _createNodeTree(nextNode);
      }

      Edge.addToBasePlanner(
        basePlanner,
        parentGraph: this,
        edgeType: EdgeType.requestItems,
        parentNode: startNode,
        childNode: nextNode,
        item: input,
      );
    }
  }

  ProdLineNode? _createResourceNode(InGameItem requiredOutput) {
    if (_surfaceProperties.resources.contains(requiredOutput)) {
      return ProdLineNode.addToBasePlanner(
        basePlanner,
        parentGraph: this,
        nodeType: NodeType.resource,
        productionLine: MagicLine.singleItemProducer(requiredOutput),
      );
    } else {
      return null;
    }
  }

  ProdLineNode? _createRecipeNode(InGameItem requiredOutput) {
    // TODO - check for valid fluid temperatures
    var baseRecipe = _surfaceProperties.defaultRecipes
        .where(
          (recipe) => recipe.results.any(
            (product) => product.item == requiredOutput.internalItem,
          ),
        )
        .firstOrNull;

    if (baseRecipe != null) {
      var quality = requiredOutput is InGameSolidItem
          ? requiredOutput.quality
          : 1;
      var inGameRecipe = InGameRecipe(baseRecipe, quality);

      var inGameMachine = InGameMachine(
        baseRecipe.sortedCraftingMachines.first,
      );

      InGameSolidItem? fuel;
      if (inGameMachine.needsSolidFuel) {
        var burner = inGameMachine.energySource as BurnerEnergySource;

        // Search existing nodes for valid fuel
        var existingNodeFuel = burner.fuelItems
            .where(
              (fuelItem) =>
                  getChangeTracker().cachedDisposalNodes[InGameSolidItem(
                    fuelItem,
                  )] !=
                  null,
            )
            .map((item) => InGameSolidItem(item));

        // Search surface for valid fuel
        var surfaceFuels = _surfaceProperties.availableSolidFuels.where(
          (surfaceFuel) => burner.fuelItems.contains(surfaceFuel.internalItem),
        );

        // Use first valid fuel
        var machineFuels = burner.fuelItems.map(
          (fuelItem) => InGameSolidItem(fuelItem),
        );

        fuel = existingNodeFuel
            .followedBy(surfaceFuels)
            .followedBy(machineFuels)
            .firstOrNull;

        if (fuel == null) {
          throw GraphException(
            'Machine $inGameMachine somehow has no acceptable fuels despite requiring fuel to run',
          );
        }
      }

      return ProdLineNode.addToBasePlanner(
        basePlanner,
        parentGraph: this,
        nodeType: NodeType.productionLine,
        productionLine: SingleRecipeLine.fromBaseMachine(
          inGameMachine,
          inGameRecipe,
          surface: surface,
          fuel: fuel,
        ),
      );
    } else {
      return null;
    }
  }

  ProdLineNode _createMagicResourceNode(InGameItem requiredOutput) =>
      ProdLineNode.addToBasePlanner(
        basePlanner,
        parentGraph: this,
        nodeType: NodeType.resource,
        productionLine: MagicLine.singleItemProducer(requiredOutput),
      );

  void _tableLayout() {
    Map<NodeElement, int> nodeToRowNumber = {};

    var consumerNodesFirstRow = 0;
    var maxRowNumber = 0;

    if (outputNodes.isNotEmpty) {
      consumerNodesFirstRow = 1;

      maxRowNumber = outputNodes.values
          .map(
            (outputNode) =>
                _determineAndReturnMaxRowNumber(outputNode, 0, nodeToRowNumber),
          )
          .reduce(math.max);
    }

    maxRowNumber = allNodes
        .where((node) => !node.nodeType.isIo && node.parents.isEmpty)
        .map(
          (node) => _determineAndReturnMaxRowNumber(
            node,
            consumerNodesFirstRow,
            nodeToRowNumber,
          ),
        )
        .fold(maxRowNumber, math.max);

    if (inputNodes.isNotEmpty) {
      maxRowNumber++;
      for (var inputNode in inputNodes.values) {
        nodeToRowNumber[inputNode] = maxRowNumber;
      }
    }

    List<List<NodeElement>> rows = List.generate(
      maxRowNumber + 1,
      (_) => [],
      growable: false,
    );

    nodeToRowNumber.forEach((node, rowNumber) => rows[rowNumber].add(node));

    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < rows[row].length; column++) {
        var topLeftCorner = Offset(
          NodeGeometryImpl.defaultPadding +
              (NodeGeometryImpl.defaultWidth +
                      NodeGeometryImpl.defaultPadding) *
                  column,
          NodeGeometryImpl.defaultPadding +
              (NodeGeometryImpl.defaultHeight +
                      NodeGeometryImpl.defaultPadding) *
                  row,
        );
        var bottomRightCorner =
            topLeftCorner +
            const Offset(
              NodeGeometryImpl.defaultWidth,
              NodeGeometryImpl.defaultHeight,
            );

        rows[row][column].getStateBuilder().updateGeometry(
          NodeGeometryImpl(Rect.fromPoints(topLeftCorner, bottomRightCorner)),
        );
      }
    }

    for (var edge in edges) {
      edge.getStateBuilder().updateGeometry(
        EdgeGeometryImpl.shortestPath(
          edge.childNode.geometry,
          edge.parentNode.geometry,
        ),
      );
    }
  }

  int _determineAndReturnMaxRowNumber(
    NodeElement node,
    int rowNumber,
    Map<NodeElement, int> nodeToRowNumber,
  ) {
    if ((nodeToRowNumber[node] ?? 0) > rowNumber) {
      return rowNumber;
    } else {
      nodeToRowNumber[node] = rowNumber;

      return node.allChildren
          .where((edge) => edge.childNode.nodeType != NodeType.input)
          .map(
            (edge) => _determineAndReturnMaxRowNumber(
              edge.childNode,
              rowNumber + 1,
              nodeToRowNumber,
            ),
          )
          .fold(rowNumber, math.max);
    }
  }
}

class GraphIo extends ProductionLineIoData {
  factory GraphIo.fromState(GraphState state) {
    var builder = GraphIoBuilder();

    for (var node in state.allNodes) {
      builder.add(node);
    }

    return builder.build();
  }

  GraphIo({
    required super.constraints,
    required super.itemIo,
    required super.totalProductionAndConsumption,
    required super.electricPowerConsumption,
    super.displayData = const [],
    required super.emissions,
  });

  const GraphIo.empty() : super.empty();
}

class GraphEvent extends NodeEvent {
  GraphEvent.geometryOp(NodeGeometry super.geometry);

  const GraphEvent();
}

class GraphException extends BasePlannerException {
  const GraphException(super.message, [super.cause]);
}

class GraphIoBuilder implements Builder<GraphIo> {
  final ItemIoBuilder constraintsBuilder = ItemIoBuilder();
  final ItemIoBuilder itemIoBuilder = ItemIoBuilder();
  final ItemIoBuilder conAndProdBuilder = ItemIoBuilder();
  double electricPowerConsumption = 0.0;
  final Map<String, double> emissions = {};

  void add(NodeElement node) {
    var ioData = node.ioData;

    if (node.nodeType == NodeType.input) {
      constraintsBuilder.addAllToInputs(ioData.constraints.inputs);
      itemIoBuilder.addAllToInputs(ioData.itemIo.inputs);
    } else if (node.nodeType == NodeType.output) {
      constraintsBuilder.addAllToOutputs(ioData.constraints.outputs);
      itemIoBuilder.addAllToOutputs(ioData.itemIo.outputs);
    }

    conAndProdBuilder.addAll(ioData.totalProductionAndConsumption);

    electricPowerConsumption += ioData.electricPowerConsumption;

    sumMaps(emissions, ioData.emissions);
  }

  @override
  GraphIo build() => GraphIo(
    constraints: constraintsBuilder.build(),
    itemIo: itemIoBuilder.build(),
    totalProductionAndConsumption: conAndProdBuilder.build(),
    electricPowerConsumption: electricPowerConsumption,
    emissions: emissions,
  );
}

enum GraphLayout { table, custom }

enum LayoutOrientation { up, left, down, right }
