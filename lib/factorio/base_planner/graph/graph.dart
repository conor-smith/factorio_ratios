import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';
import 'package:factorio_ratios/utility/builder.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'graph_state.dart';

/// Represents a graph of [NodeElement]s connected by [Edge]s.
class Graph
    with EventNotifier<GraphEvent>, ProductionLine<GraphIo>
    implements NodeElement<GraphState, GraphEvent> {
  @override
  final BasePlanner basePlanner;
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
  NodeGeometryImpl get geometry => state.geometry;
  @override
  Set<Edge> get parents => state.parents;
  @override
  Set<Edge> get children => state.children;
  @override
  GraphIo get ioData => state.ioData;
  Set<Graph> get graphNodes => state.graphNodes;
  Set<ProdLineNode> get prodLineNodes => state.prodLineNodes;
  Map<InGameItem, ProdLineNode> get outputNodes => state.outputNodes;
  Map<InGameItem, ProdLineNode> get inputNodes => state.inputNodes;
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

  bool get isRoot => this == parentGraph;
  bool get hasBuilder => _builder != null;

  // TODO
  @override
  ItemIo? get ioRatios => null;

  Graph.addToBasePlanner(
    this.basePlanner, {
    required this.parentGraph,
    this.surface,
    String name = 'graph',
    Icon? icon,
    NodeGeometryImpl geometry = NodeGeometryImpl.uninitialised,
  }) : _state = GraphStateImpl._initial(
         name: name,
         icon: icon ?? surface?.icon,
         geometry: geometry,
       ),
       _surfaceProperties =
           basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty {
    _builder = GraphStateBuilder.from(this, _state);
    _builder!.addSelf();
  }

  Graph.rootGraph(this.basePlanner, [this.surface])
    : _state = GraphStateImpl._initial(
        name: 'Root Graph',
        icon: surface?.icon,
        geometry: NodeGeometryImpl.uninitialised,
      ),
      _surfaceProperties =
          basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty {
    parentGraph = this;
  }

  @override
  set state(GraphStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();
    _builder = null;
    _state = state;
  }

  @override
  GraphStateBuilder getStateBuilder() {
    _builder ??= GraphStateBuilder.from(this, _state);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => basePlanner.selectedElements.contains(this);

  @override
  void select() => basePlanner.selectElement(this);

  @override
  void deselect() => basePlanner.deselectElement(this);

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
  void notifyListenersOfStateUpdate(
    GraphStateImpl oldState,
    GraphStateImpl newState,
  ) {
    if (hasListeners) {
      if (oldState.geometry != newState.geometry) {
        notifyListeners(GraphEvent.geometryOp(newState.geometry));
      } else if (!compareSets(oldState.allNodes, newState.allNodes) ||
          compareSets(oldState.edges, newState.edges)) {
        notifyListeners(
          GraphEvent.updateNodesAndEdges(
            oldNodes: oldState.allNodes,
            newNodes: newState.allNodes,
            oldEdges: oldState.edges,
            newEdges: newState.edges,
          ),
        );
      }
    }
  }

  /// Clears all nodes except IO nodes
  void clear() {
    basePlanner.buildNextSnapshot(() {
      var nonIoNodes = allNodes.where((node) => !node.nodeType.isIo).toList();
      for (var node in nonIoNodes) {
        node.getStateBuilder().removeSelf();
      }
    });
  }

  // TODO
  void determineIoOfAllNodes(Set<ProdLineNode> nodesToUpdateIo) {
    basePlanner.getSnapshotBuilder().throwIfNotBuilding();

    // Can technically be called anywhere, but good to ensure it's only called once
    if (!isRoot) {
      throw const GraphException(
        'This operation can only be performed by root graph',
      );
    }
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
        basePlanner: basePlanner,
        parentGraph: this,
        nodeType: NodeType.consumer,
        productionLine: MagicLine.singleItemConsumer(item),
      );

      _createNodeTree(consumerNode);

      // TODO: Is this the best layout?
      defaultLayout();
    });
  }

  void defaultLayout() {
    if (allNodes.isEmpty) {
      return;
    }

    basePlanner.buildNextSnapshot(() {
      Map<NodeElement, int> nodeToRowNumber = {};

      var consumerNodesFirstRow = 0;
      var maxRowNumber = 0;

      if (outputNodes.isNotEmpty) {
        consumerNodesFirstRow = 1;

        maxRowNumber = outputNodes.values
            .map(
              (outputNode) => _determineAndReturnMaxRowNumber(
                outputNode,
                0,
                nodeToRowNumber,
              ),
            )
            .reduce(_returnLargest);
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
          .fold(maxRowNumber, _returnLargest);

      if (inputNodes.isNotEmpty) {
        for (var inputNode in inputNodes.values) {
          nodeToRowNumber[inputNode] = maxRowNumber;
        }

        maxRowNumber++;
      }

      List<List<NodeElement>> rows = List.generate(
        maxRowNumber,
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
            edge.parent.geometry,
            edge.child.geometry,
          ),
        );
      }
    });
  }

  @override
  GraphIo calculateIoData([ItemIo constraints = ItemIo.empty]) => state.ioData;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  void _createNodeTree(NodeElement startNode) {
    // Ignore items that already have an input edge
    var requiredInputs = startNode.inputItems.difference(
      startNode.children.map((edge) => edge.item).toSet(),
    );

    for (var input in requiredInputs) {
      var nextNode =
          getStateBuilder().cachedNodeOutputIndex[input]?.firstOrNull;

      if (nextNode == null) {
        nextNode =
            _createResourceNode(input) ??
            _createRecipeNode(input) ??
            _createMagicResourceNode(input);

        _createNodeTree(nextNode);
      }

      Edge.addToBasePlanner(
        basePlanner: basePlanner,
        parentGraph: this,
        edgeType: EdgeType.requestItems,
        parent: startNode,
        child: nextNode,
        item: input,
      );
    }
  }

  ProdLineNode? _createResourceNode(InGameItem requiredOutput) {
    if (_surfaceProperties.resources.contains(requiredOutput)) {
      return ProdLineNode.addToBasePlanner(
        basePlanner: basePlanner,
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
        basePlanner.sortedMachines.firstWhere(
          (machine) => machine.recipes.contains(baseRecipe),
        ),
      );

      InGameSolidItem? fuel;
      if (inGameMachine.needsSolidFuel) {
        var burner = inGameMachine.energySource as BurnerEnergySource;

        // Search existing nodes for valid fuel
        var existingNodeFuel = burner.fuelItems
            .where(
              (fuelItem) =>
                  getStateBuilder().cachedDisposalNodes[InGameSolidItem(
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
        basePlanner: basePlanner,
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
        basePlanner: basePlanner,
        parentGraph: this,
        nodeType: NodeType.resource,
        productionLine: MagicLine.singleItemProducer(requiredOutput),
      );

  int _determineAndReturnMaxRowNumber(
    NodeElement node,
    int rowNumber,
    Map<NodeElement, int> nodeToRowNumber,
  ) {
    if ((nodeToRowNumber[node] ?? 0) > rowNumber) {
      return rowNumber;
    } else {
      nodeToRowNumber[node] = rowNumber;
      int nextRow = rowNumber + 1;

      return node.children
          .where((edge) => edge.child.nodeType != NodeType.input)
          .map(
            (edge) => _determineAndReturnMaxRowNumber(
              edge.child,
              nextRow,
              nodeToRowNumber,
            ),
          )
          .fold(nextRow, _returnLargest);
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
    required super.io,
    required super.totalProductionAndConsumption,
    required super.electricPowerConsumption,
    super.displayData = const [],
    required super.emissions,
  });

  const GraphIo.empty() : super.empty();
}

class GraphEvent implements NodeEvent {
  @override
  final NodeEventType nodeEventType;
  @override
  final NodeGeometry? geometry;

  final GraphEventType graphEventType;

  final Set<NodeElement> newNodes, removedNodes;
  final Set<Edge> newEdges, removedEdges;

  GraphEvent.geometryOp(NodeGeometry geometry)
    : this._nodeEvent(NodeEventType.geometryOp, geometry);

  GraphEvent.updateNodesAndEdges({
    required Set<NodeElement> oldNodes,
    required Set<NodeElement> newNodes,
    required Set<Edge> oldEdges,
    required Set<Edge> newEdges,
  }) : this._graphEvent(
         GraphEventType.updateNodesAndEdges,
         removedNodes: oldNodes.difference(newNodes),
         newNodes: newNodes.difference(oldNodes),
         removedEdges: oldEdges.difference(newEdges),
         newEdges: newEdges.difference(oldEdges),
       );

  GraphEvent._nodeEvent(this.nodeEventType, [this.geometry])
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
       geometry = null;
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
    var io = node.ioData;

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

int _returnLargest(int val1, int val2) => val1 > val2 ? val1 : val2;
