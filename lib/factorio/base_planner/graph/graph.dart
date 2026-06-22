import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/io_node/io_node.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/node/production_line_node/production_line_node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';
import 'package:factorio_ratios/utility/utility.dart';
import 'package:sorted_list/sorted_list.dart';

part 'graph_state.dart';

/// Represents a graph of [NodeElement]s connected by [Edge]s.
class Graph
    with EventNotifier<GraphEvent>
    implements NodeElement<GraphState, GraphEvent>, ProductionLine<GraphIo> {
  final BasePlanner _basePlanner;
  final Surface? surface;
  @override
  late final Graph parentGraph;
  final SurfaceProperties _surfaceProperties;

  GraphStateImpl _state;
  GraphStateBuilder? _builder;

  @override
  GraphState get state => _builder ?? _state;

  // For convenience
  @override
  String get name => state.name;
  @override
  Icon? get icon => state.icon;
  @override
  NodeGeometryImpl get nodeGeometry => state.nodeGeometry;
  @override
  Set<Edge> get parents => state.parents;
  @override
  Set<Edge> get children => state.children;
  @override
  Map<InGameItem, List<Edge>> get inputEdges => state.inputEdges;
  @override
  Map<InGameItem, List<Edge>> get outputEdges => state.outputEdges;
  @override
  GraphIo? get io => state.io;
  Set<Graph> get graphNodes => state.graphNodes;
  Set<ProdLineNode> get prodLineNodes => state.prodLineNodes;
  Map<InGameItem, IoNode> get outputNodes => throw UnimplementedError();
  Map<InGameItem, IoNode> get inputNodes => throw UnimplementedError();
  Set<NodeElement> get allNodes => state.allNodes;
  Set<Edge> get edges => state.edges;
  @override
  Set<InGameItem> get inputItems => state.inputItems;
  @override
  Set<InGameItem> get outputItems => state.outputItems;

  @override
  ProductionLineType get productionLineType => ProductionLineType.graph;
  @override
  NodeType get nodeType => NodeType.productionLine;
  @override
  ItemIo? get requirements => null;
  @override
  ProductionLine get productionLine => this;

  // TODO
  @override
  ItemIo? get ioRatios => null;

  Graph.addToBasePlanner(
    BasePlanner basePlanner, {
    required this.parentGraph,
    this.surface,
    Icon? icon,
  }) : _basePlanner = basePlanner,
       _state = GraphStateImpl._initial(icon: icon ?? surface?.icon),
       _surfaceProperties =
           basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty {
    _builder = GraphStateBuilder._new(this);
  }

  Graph.rootGraph(BasePlanner basePlanner, [this.surface])
    : _basePlanner = basePlanner,
      _state = GraphStateImpl._initial(icon: surface?.icon),
      _surfaceProperties =
          basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty {
    parentGraph = this;
  }

  @override
  void remove() => GraphStateBuilder._remove(this);

  @override
  set state(GraphStateImpl state) {
    _basePlanner.throwIfMutationNotPermitted();
    _builder = null;

    // Validate state, update listeners
    _state = state;
  }

  @override
  GraphStateBuilder getStateBuilder() {
    _builder ??= GraphStateBuilder._from(this);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => _basePlanner.selectedElements.contains(this);

  @override
  void select() => _basePlanner.selectElement(this);

  @override
  void deselect() => _basePlanner.deselectElement(this);

  @override
  NodeElement getOutputItemNode(InGameItem item) {
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
  NodeElement getInputItemNode(InGameItem item) {
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
  void notifyListenersOfGeometryUpdate(NodeGeometry nodeGeometry) =>
      notifyListeners(GraphEvent.geometryOp(nodeGeometry));

  @override
  void notifyListenersOfStateUpdate(
    GraphStateImpl oldState,
    GraphStateImpl newState,
  ) {
    // TODO: implement notifyListenersOfStateUpdate
    throw UnimplementedError();
  }

  void addConsumerNodeAndTree(InGameItem item) {
    if (surface == null) {
      throw const GraphException(
        'Cannot build node tree of graph with no surface',
      );
    }

    var existingConsumerNode = prodLineNodes
        .where(
          (node) =>
              node.nodeType == NodeType.consumer &&
              node.inputItems.contains(item),
        )
        .firstOrNull;
    if (existingConsumerNode != null) {
      return;
    }

    _basePlanner.buildNextSnapshot(() {
      var consumerNode = ProdLineNode.addToBasePlanner(
        basePlanner: _basePlanner,
        parentGraph: this,
        nodeType: NodeType.consumer,
        productionLine: MagicLine.singleItemConsumer(item),
      );

      _NodeItemIndex outputIndex = {};
      for (var node in allNodes.where(
        (node) => node.nodeType.parentsPermitted,
      )) {
        _addOutputToIndex(outputIndex, node);
      }

      _createNodeTree(consumerNode, outputIndex, {});

      // TODO: Is this the best layout?
      defaultLayout();
    });
  }

  void defaultLayout() {
    if (allNodes.isEmpty) {
      return;
    }

    _basePlanner.buildNextSnapshot(() {
      int numberOfRows = 0;
      Map<NodeElement, int> nodeToRowNumber = {};

      for (var rootNode in allNodes.where((node) => node.parents.isEmpty)) {
        var newNumberOfRows = _determineRowsAndReturnNumberOfRows(
          rootNode,
          0,
          nodeToRowNumber,
          {},
        );
        if (newNumberOfRows > numberOfRows) {
          numberOfRows = newNumberOfRows;
        }
      }

      List<List<NodeElement>> rows = List.generate(
        numberOfRows + 1,
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
            edge.parent.nodeGeometry,
            edge.child.nodeGeometry,
          ),
        );
      }
    });
  }

  @override
  GraphIo calculate(ItemIo constraints) {
    var ioBuilder = GraphIoBuilder();

    for (var node in allNodes) {
      ioBuilder.add(node);
    }

    return ioBuilder.build();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  void _addOutputToIndex(_NodeItemIndex nodeOutputIndex, NodeElement node) {
    for (var output in node.outputItems) {
      // TODO: optimise this
      nodeOutputIndex.update(
        output,
        (nodeList) => nodeList..add(node),
        ifAbsent: () => SortedList(
          (node1, node2) => node1.nodeType.compareTo(node2.nodeType),
        )..add(node),
      );
    }
  }

  void _createNodeTree(
    NodeElement startNode,
    _NodeItemIndex outputIndex,
    Set<NodeElement> visitedNodes,
  ) {
    visitedNodes.add(startNode);

    var inputEdges = startNode.inputEdges;

    for (var inputItem in startNode.inputItems.where(
      (input) => inputEdges.containsKey(input),
    )) {
      var nextNode = outputIndex[inputItem]?.firstOrNull;

      if (nextNode == null) {
        nextNode =
            _createResourceNode(inputItem) ??
            _createRecipeNode(outputIndex, inputItem) ??
            _createMagicResourceNode(inputItem);
        _addOutputToIndex(outputIndex, nextNode);
      }

      Edge.addToBasePlanner(
        basePlanner: _basePlanner,
        parentGraph: this,
        edgeType: EdgeType.requestItems,
        parent: startNode,
        child: nextNode,
        item: inputItem,
      );

      if (!visitedNodes.contains(nextNode)) {
        _createNodeTree(nextNode, outputIndex, visitedNodes);
      }
    }
  }

  ProdLineNode? _createResourceNode(InGameItem requiredOutput) {
    if (_surfaceProperties.resources.contains(requiredOutput)) {
      return ProdLineNode.addToBasePlanner(
        basePlanner: _basePlanner,
        parentGraph: this,
        nodeType: NodeType.resource,
        productionLine: MagicLine.singleItemProducer(requiredOutput),
      );
    } else {
      return null;
    }
  }

  ProdLineNode? _createRecipeNode(
    _NodeItemIndex outputIndex,
    InGameItem requiredOutput,
  ) {
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
        _basePlanner.sortedMachines.firstWhere(
          (machine) => machine.recipes.contains(baseRecipe),
        ),
      );

      InGameSolidItem? fuel;
      if (inGameMachine.needsSolidFuel) {
        var burner = inGameMachine.energySource as BurnerEnergySource;

        // Search existing nodes for valid fuel
        var existingNodeFuel = burner.fuelItems
            .where((fuelItem) => outputIndex[InGameItem(fuelItem)] != null)
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
            .first;
      }

      return ProdLineNode.addToBasePlanner(
        basePlanner: _basePlanner,
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
        basePlanner: _basePlanner,
        parentGraph: this,
        nodeType: NodeType.resource,
        productionLine: MagicLine.singleItemProducer(requiredOutput),
      );

  int _determineRowsAndReturnNumberOfRows(
    NodeElement node,
    int rowNumber,
    Map<NodeElement, int> nodeToRowNumber,
    Set<NodeElement> visitedNodes,
  ) {
    visitedNodes.add(node);
    int maxRowNumber = rowNumber;

    if (rowNumber > (nodeToRowNumber[node] ?? 0)) {
      nodeToRowNumber[node] = rowNumber;

      var childNodes = node.children
          .map((edge) => edge.child)
          .where(
            (childNode) =>
                childNode.parentGraph == this &&
                !visitedNodes.contains(childNode),
          );

      for (var childNode in childNodes) {
        var newMaxRowNumber = _determineRowsAndReturnNumberOfRows(
          childNode,
          rowNumber + 1,
          nodeToRowNumber,
          visitedNodes,
        );

        if (newMaxRowNumber > maxRowNumber) {
          maxRowNumber = newMaxRowNumber;
        }
      }
    }

    return rowNumber;
  }
}

class GraphIo extends ProductionLineIo {
  factory GraphIo.fromState(GraphState state) {
    var builder = GraphIoBuilder();

    for (var node in state.allNodes) {
      builder.add(node);
    }

    return builder.build();
  }

  GraphIo({
    required super.constraints,
    required super.io,
    required super.totalProductionAndConsumption,
    required super.electricPowerConsumption,
    super.displayData = const [],
    required super.emissions,
  });
}

class GraphEvent implements NodeEvent {
  @override
  final NodeEventType nodeEventType;
  @override
  final NodeGeometry? nodeGeometry;

  final GraphEventType graphEventType;

  final Set<NodeElement> newNodes, removedNodes;
  final Set<Edge> newEdges, removedEdges;

  GraphEvent.geometryOp(NodeGeometry nodeGeometry)
    : this._nodeEvent(NodeEventType.geometryOp, nodeGeometry);

  GraphEvent._nodeEvent(this.nodeEventType, [this.nodeGeometry])
    : graphEventType = GraphEventType.nodeEvent,
      newNodes = const {},
      removedNodes = const {},
      newEdges = const {},
      removedEdges = const {};

  GraphEvent._graphEvent(
    this.graphEventType, {
    this.newNodes = const {},
    this.removedNodes = const {},
    this.newEdges = const {},
    this.removedEdges = const {},
  }) : nodeEventType = NodeEventType.other,
       nodeGeometry = null;
}

class GraphException extends BasePlannerException {
  const GraphException(super.message, [super.cause]);
}

class GraphIoBuilder implements Builder<GraphIo> {
  final ItemAmounts inputConstraints = {};
  final ItemAmounts outputConstraints = {};
  final ItemAmounts input = {};
  final ItemAmounts output = {};
  final ItemAmounts consumption = {};
  final ItemAmounts production = {};
  double electricPowerConsumption = 0.0;
  final Map<String, double> emissions = {};

  void add(NodeElement node) {
    var io = node.io;

    if (io != null) {
      if (node.nodeType == NodeType.input) {
        sumMaps(inputConstraints, io.constraints.inputs);
        sumMaps(input, io.io.inputs);
      } else if (node.nodeType == NodeType.output) {
        sumMaps(outputConstraints, io.constraints.outputs);
        sumMaps(output, io.io.outputs);
      }

      sumMaps(consumption, io.totalProductionAndConsumption.inputs);
      sumMaps(production, io.totalProductionAndConsumption.outputs);

      electricPowerConsumption += io.electricPowerConsumption;

      sumMaps(emissions, io.emissions);
    }
  }

  @override
  GraphIo build() => GraphIo(
    constraints: ItemIo(inputs: inputConstraints, outputs: outputConstraints),
    io: ItemIo(inputs: input, outputs: output),
    totalProductionAndConsumption: ItemIo(
      inputs: consumption,
      outputs: production,
    ),
    electricPowerConsumption: electricPowerConsumption,
    emissions: emissions,
  );
}

enum GraphEventType { updateNodesAndEdges, childrenGeometryUpdate, nodeEvent }

typedef _NodeItemIndex = Map<InGameItem, SortedList<NodeElement>>;
