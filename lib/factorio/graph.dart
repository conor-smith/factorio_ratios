import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/production_line.dart';

part 'graph/node_and_edge.dart';

class BaseGraph extends ProductionLine {
  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _parents = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _children = {};

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};
  Map<ItemData, double>? _requirements;
  Map<ItemData, double>? _totalIoPerSecond;

  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);
  @override
  Map<ItemData, double>? get requirements => _requirements;
  @override
  Map<ItemData, double>? get totalIoPerSecond => _totalIoPerSecond;

  @override
  bool get immutableIo => false;

  @override
  void update(Map<ItemData, double> newRequirements) {
    super.update(newRequirements);
  }

  @override
  void reset() {
    for (var node in _nodes) {
      node.reset();
    }

    _totalIoPerSecond = null;
    _requirements = null;
  }

  // Method is public to allow UI to use when displaying tree
  // 'Height' of a node is the length of the longest path
  // Nodes with the same value can be updated in any order
  List<List<ProdLineNode>> getNodeHeights(Iterable<ProdLineNode> nodes) {
    Map<ProdLineNode, int> heightMap = {};

    int maxHeight = 0;
    for (var node in nodes) {
      int newMax = _getDescendantsHeight(node, heightMap, 0);

      maxHeight = newMax > maxHeight ? newMax : maxHeight;
    }

    List<List<ProdLineNode>> flippedMap = List.generate(
      maxHeight + 1,
      (_) => [],
    );

    heightMap.forEach((node, height) => flippedMap[height].add(node));

    return flippedMap;
  }

  void _updateNodesAndChildren(
    Map<ProdLineNode, Map<ItemData, double>> nodesAndRequirements,
  ) {
    var orderOfUpdate = getNodeHeights(nodesAndRequirements.keys);

    var allOrderedNodes = orderOfUpdate.expand((entry) => entry);

    // Exists so changes can be rolled back if exception occurs
    Map<ProdLineNode, Map<ItemData, double>?> oldRequirementsMap = {};
    Map<DirectedEdge, double?> oldAmountMap = {};
    List<ProdLineNode> newNodes = [];

    try {
      for (var node in allOrderedNodes) {
        _updateNodeAndChildEdges(
          node,
          nodesAndRequirements[node],
          oldRequirementsMap,
          oldAmountMap,
          newNodes,
        );
      }
    } catch (e) {
      oldRequirementsMap.forEach((node, oldRequirements) {
        if (oldRequirements == null) {
          node.reset();
        } else {
          node.update(oldRequirements);
        }
      });

      oldAmountMap.forEach((edge, oldAmount) {
        edge._amount = oldAmount;
      });

      for (var newNode in newNodes) {
        newNode.removeFromGraph();
      }

      rethrow;
    }
  }

  void _updateNodeAndChildEdges(
    ProdLineNode node,
    Map<ItemData, double>? newRequirements,
    Map<ProdLineNode, Map<ItemData, double>?> oldRequirementsMap,
    Map<DirectedEdge, double?> oldAmountMap,
    List<ProdLineNode> newNodes,
  ) {
    oldRequirementsMap[node] = node.requirements;

    // Requirements either comes from parents, or from nodeAndRequirements map
    // In the event that both are populated, an exception is thrown
    Map<ItemData, double> parentRequirements = {};
    for (var parent in node.parents) {
      if (parent.amount != null) {
        double amount = parent.flowDirection == ItemFlowDirection.childToParent
            ? parent._amount!
            : -parent._amount!;

        parentRequirements.update(
          parent.item,
          (currentAmount) => currentAmount + amount,
          ifAbsent: () => amount,
        );
      } else {
        throw FactorioException('Parent node has not been initialised');
      }
    }

    if (parentRequirements.isEmpty && newRequirements != null) {
      node.update(newRequirements);
    } else if (parentRequirements.isNotEmpty && newRequirements == null) {
      node.update(parentRequirements);
    } else if (parentRequirements.isEmpty && newRequirements == null) {
      // Theoretically should never get here
      throw const FactorioException('No requirements specified');
    } else if (parentRequirements.isNotEmpty && newRequirements != null) {
      // TODO - Is it possible to resolve conficts?
      throw const FactorioException('Conflicting requirements');
    }

    Map<ItemData, double> io = node.totalIoPerSecond!;
    List<DirectedEdge> allEdges = [...node.parents, ...node.children];

    io.forEach((itemData, amount) {
      if (amount > 0) {
        double totalRequested = node.parents
            .where((edge) => edge.item == itemData)
            .map((edge) => edge._amount!)
            .reduce((amount1, amount2) => amount1 + amount2);

        double difference = totalRequested - amount;
        // Account for floating point issues
        bool withinBounds = difference.abs() < totalRequested * 0.001;

        // Create or use existing disposal node if excess production
        if (!withinBounds && difference > 0) {
          DirectedEdge? acceptExcessEdge = node.children
              .where(
                (edge) =>
                    edge.item == itemData &&
                    edge._edgeType == EdgeType.acceptExcess,
              )
              .firstOrNull;
          if (acceptExcessEdge == null) {
            var excessDisposalNode = ProdLineNode.addToGraph(
              parentGraph: this,
              type: NodeType.consumer,
              line: IoLine(inputs: {itemData}),
            );
            acceptExcessEdge = DirectedEdge.addToGraph(
              parentGraph: this,
              item: itemData,
              parent: node,
              child: excessDisposalNode,
              edgeType: EdgeType.acceptExcess,
            );

            newNodes.add(excessDisposalNode);

            excessDisposalNode.update({itemData: -difference});
          }

          acceptExcessEdge._amount = difference;
        } else if (!withinBounds && difference < 0) {
          throw FactorioException(
            'Could not produce required amount of "$itemData"',
          );
        }
      } else {
        // TODO - Account for multiple producers of single item
        DirectedEdge? inputEdge = allEdges
            .where((edge) => edge.item == itemData)
            .firstOrNull;

        if (inputEdge == null) {
          throw FactorioException('No input provided for item "$itemData"');
        } else if (inputEdge._edgeType == EdgeType.requestItems) {
          oldAmountMap[inputEdge] = inputEdge._amount;

          inputEdge._amount = amount;
        }
      }
    });
  }

  // Returns the depth
  int _getDescendantsHeight(
    ProdLineNode node,
    Map<ProdLineNode, int> heightMap,
    int currentHeight,
  ) {
    int existingHeight = heightMap[node] ?? -1;
    if (currentHeight > existingHeight) {
      heightMap[node] = currentHeight;
      int maxHeight = currentHeight;

      for (var childEdge in node.children) {
        int newMax = _getDescendantsHeight(
          childEdge.child,
          heightMap,
          currentHeight + 1,
        );

        maxHeight = newMax > maxHeight ? newMax : maxHeight;
      }

      return maxHeight;
    } else {
      return existingHeight;
    }
  }
}
