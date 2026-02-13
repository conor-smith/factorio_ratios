
import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/production_line.dart';

enum NodeType { resource, disposal, input, output, productionLine }

enum ItemFlowDirection { parentToChild, childToParent }

enum EdgeType { requestItems, acceptExcess }

class PlanetaryBase extends ProductionLine {
  /*
   * TODO
   * Handle scenarios with both a disposal and output node for an item
   * Handle excess items and disposal nodes
   * Handle multiple nodes with the same output
   * Handle output nodes requiring rocket launches
   */
  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};
  final Map<ItemData, double> _totalIoPerSecond = {};
  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};

  // Results in some duplication, but makes lookups much quicker
  final Map<ProdLineNode, Set<DirectedEdge>> _parents = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _children = {};

  // Lookup for output and disposal nodes
  final Map<ItemData, ProdLineNode> _outputNodes = {};
  final Map<ItemData, ProdLineNode> _disposalNodes = {};
  // Lookup for input, resource, and productionLine nodes
  final Map<ItemData, ProdLineNode> _producerNodes = {};

  GraphUpdates _graphUpdates = GraphUpdates._();

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );
  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);

  GraphUpdates get updates {
    GraphUpdates toReturn = _graphUpdates;
    _graphUpdates = GraphUpdates._();
    return toReturn;
  }

  @override
  void update(Map<ItemData, double> requirements) {
    Set<ItemData> outputs = allOutputs;

    for (var itemD in requirements.keys) {
      if (!outputs.contains(itemD)) {
        throw FactorioException('Item "$itemD" is not produced by this base');
      }
    }

    requirements.forEach((itemD, amount) {
      _outputNodes[itemD]!._requirements[itemD] = -amount;
    });

    _updateNodeAndChildrenOutputs(
      _outputNodes.values
          .where((node) => node._type == NodeType.output)
          .toList(),
    );
  }

  void addOutputNode(ItemData itemD) {
    if (_disposalNodes.containsKey(itemD)) {
      _convertDisposalToOutput(_disposalNodes[itemD]!);
    } else if (!_outputNodes.containsKey(itemD)) {
      ProdLineNode newOutputNode = ProdLineNode._addToGraph(
        parentGraph: this,
        type: NodeType.output,
        initialRequirements: {itemD: -1},
      );
      _updateEdgesForNode(newOutputNode, false);
    }
  }

  void _convertDisposalToOutput(ProdLineNode node) {
    // TODO
    throw UnimplementedError();
  }

  void _updateEdgesForNode(ProdLineNode updatedNode, bool nodeIsNew) {
    // TODO - Handle nodes that lose children, not just gain
    // TODO - Handle excess output and disposal nodes
    for (var itemD in updatedNode.inputs) {
      if (updatedNode.children
          .where(
            (edge) =>
                edge._flowDirection == ItemFlowDirection.childToParent &&
                edge.item == itemD,
          )
          .isEmpty) {
        ProdLineNode childNodeForItem;
        bool childNodeIsNew;
        if (_producerNodes.containsKey(itemD)) {
          childNodeForItem = _producerNodes[itemD]!;
          childNodeIsNew = true;
        } else {
          childNodeForItem = ProdLineNode._addToGraph(
            parentGraph: this,
            type: NodeType.resource,
            initialRequirements: {itemD: 1},
          );
          childNodeIsNew = false;
        }

        DirectedEdge._addToGraph(
          parentGraph: this,
          item: itemD,
          parent: updatedNode,
          child: childNodeForItem,
          flowDirection: ItemFlowDirection.childToParent,
          edgeType: EdgeType.requestItems,
        );

        if (!nodeIsNew && !childNodeIsNew) {
          _checkForCycle(updatedNode, {});
        }
      }
    }
  }

  void _checkForCycle(
    ProdLineNode currentNode,
    Set<ProdLineNode> previousNodes,
  ) {
    if (previousNodes.contains(currentNode)) {
      throw const FactorioException('Cycle detected');
    }

    previousNodes.add(currentNode);
    for (var childNode in _children[currentNode]!.map((edge) => edge.child)) {
      _checkForCycle(childNode, previousNodes);
    }
    previousNodes.remove(currentNode);
  }

  void _updateNodeAndChildrenOutputs(List<ProdLineNode> nodes) {
    // TODO - account for excess output
    Map<ProdLineNode, int> orderOfUpdate = {};

    for (var node in nodes) {
      _determineOrder(node, 0, orderOfUpdate);
    }

    var entries = orderOfUpdate.entries.toList();
    entries.sort((entry1, entry2) => entry1.value.compareTo(entry2.value));
    List<ProdLineNode> orderedNodes = entries
        .map((entry) => entry.key)
        .toList();

    for (var node in orderedNodes) {
      // Build new requirements from parents (if applicable)
      if (node._type != NodeType.output) {
        Map<ItemData, double> newRequirements = {};

        for (var parentEdge in node.parents) {
          int multiplier =
              parentEdge._flowDirection == ItemFlowDirection.childToParent
              ? 1
              : -1;
          double requestedAmount = parentEdge._amount * multiplier;

          newRequirements.update(
            parentEdge.item,
            (amount) => amount + requestedAmount,
            ifAbsent: () => requestedAmount,
          );

          node._requirements.clear();
          node._requirements.addAll(newRequirements);
          node._updateLine();
        }
      }

      // Update all child edges
      Map<ItemData, double> nodeIo = node.totalIoPerSecond;
      for (var childEdge in node.children) {
        childEdge._amount = nodeIo[childEdge.item]! * -1;
      }
    }
  }

  void _determineOrder(
    ProdLineNode currentNode,
    int currentOrder,
    Map<ProdLineNode, int> orderOfUpdate,
  ) {
    if (!orderOfUpdate.containsKey(currentNode) ||
        orderOfUpdate[currentNode]! > currentOrder) {
      orderOfUpdate[currentNode] = currentOrder;

      for (var childEdge in currentNode.children) {
        _determineOrder(childEdge.child, currentOrder + 1, orderOfUpdate);
      }
    }
  }
}

class ProdLineNode {
  final PlanetaryBase parentGraph;
  NodeType _type;
  ProductionLine? _line;
  final Map<ItemData, double> _requirements;

  late final Map<ItemData, double> requirements = UnmodifiableMapView(
    _requirements,
  );

  late final Set<DirectedEdge> parents = UnmodifiableSetView(
    parentGraph._parents[this]!,
  );
  late final Set<DirectedEdge> children = UnmodifiableSetView(
    parentGraph._children[this]!,
  );

  ProdLineNode._addToGraph({
    required this.parentGraph,
    required NodeType type,
    required Map<ItemData, double>? initialRequirements,
    ProductionLine? line,
  }) : _type = type,
       _line = line,
       _requirements = initialRequirements ?? {} {
    parentGraph._nodes.add(this);
    parentGraph._parents[this] = {};
    parentGraph._children[this] = {};

    parentGraph._graphUpdates.newNodes.add(this);
  }

  NodeType get type => _type;
  ProductionLine? get productionLine => _line;

  Set<ItemData> get outputs =>
      _line?.allOutputs ??
      Set.unmodifiable(
        _requirements.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key),
      );
  Set<ItemData> get inputs =>
      _line?.allInputs ??
      Set.unmodifiable(
        _requirements.entries
            .where((entry) => entry.value < 0)
            .map((entry) => entry.key),
      );
  Map<ItemData, double> get totalIoPerSecond =>
      _line?.totalIoPerSecond ?? requirements;

  void makeSingleRecipe(ImmutableModuledMachineAndRecipe mmr) {
    // TODO
  }

  void _updateLine() => _line?.update(_requirements);

  void _removeFromGraph() {
    // TODO Remove orphans
    parentGraph._nodes.remove(this);

    for (var child in {...children, ...parents}) {
      child._removeFromGraph();
    }
    parentGraph._parents.remove(this);
    parentGraph._children.remove(this);

    switch (_type) {
      case NodeType.disposal:
      case NodeType.output:
        for (var itemD in _requirements.keys) {
          parentGraph._outputNodes.remove(itemD);
        }
      case NodeType.input:
      case NodeType.resource:
      case NodeType.productionLine:
        for (var itemD in _requirements.keys) {
          parentGraph._producerNodes.remove(itemD);
        }
    }

    if (!parentGraph._graphUpdates.newNodes.remove(this)) {
      parentGraph._graphUpdates.removedNodes.add(this);
    }
  }
}

class DirectedEdge {
  final PlanetaryBase parentGraph;
  final ItemData item;
  final ProdLineNode parent;
  final ProdLineNode child;
  double _amount;
  ItemFlowDirection _flowDirection;
  EdgeType _edgeType;

  double get amount => _amount;
  ItemFlowDirection get flowDirection => _flowDirection;
  EdgeType get edgeType => _edgeType;

  DirectedEdge._addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double initialAmount = 0,
    required ItemFlowDirection flowDirection,
    required EdgeType edgeType,
  }) : _amount = initialAmount,
       _flowDirection = flowDirection,
       _edgeType = edgeType {
    parentGraph._edges.add(this);
    parentGraph._parents[child]!.add(this);
    parentGraph._children[parent]!.add(this);

    parentGraph._graphUpdates.newEdges.add(this);
  }

  void _removeFromGraph() {
    parentGraph._edges.remove(this);
    parentGraph._parents[child]!.remove(this);
    parentGraph._children[parent]!.remove(this);

    if (!parentGraph._graphUpdates.newEdges.remove(this)) {
      parentGraph._graphUpdates.removedEdges.add(this);
    }
  }
}

class GraphUpdates {
  final Set<ProdLineNode> newNodes = {};
  final Set<ProdLineNode> removedNodes = {};
  final Set<DirectedEdge> newEdges = {};
  final Set<DirectedEdge> removedEdges = {};

  GraphUpdates._();
}
