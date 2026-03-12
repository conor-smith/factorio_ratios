import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:flutter/painting.dart';

part 'graph/edge.dart';
part 'graph/node.dart';

/*
 * Maintains a full graph
 * This acts as the state for the application, and the single source of truth
 * Every graph, edge, and widget will have a listener in the form of a widget
 * The widget will be the "owner" of it's respective element
 * 
 * Widgets are still largely responsible for their own state
 * As such, they can update their own state as they need
 */
class BaseGraph extends ProductionLine {
  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _parents = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _children = {};

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};
  ItemIo? _requirements;
  ItemIo? _totalIoPerSecond;

  Function(
    List<ProdLineNode> newNodes,
    List<DirectedEdge> newEdges,
    List<ProdLineNode> removedNodes,
    List<DirectedEdge> removedEdges,
  )?
  _callBackOnChange;

  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);
  @override
  ItemIo? get requirements => _requirements;
  @override
  ItemIo? get totalIoPerSecond => _totalIoPerSecond;
  @override
  String get type => 'graph';

  @override
  bool get immutableIo => false;

  @override
  void update(ItemIo newRequirements) {
    super.update(newRequirements);

    // TODO - better error message
    throw const FactorioException('Do not call this method');
  }

  @override
  void reset() {
    for (var node in _nodes) {
      node.reset();
    }

    _totalIoPerSecond = null;
    _requirements = null;
  }

  void graphUpdate(ItemIo newRequirements, {bool updateListeners = false}) {
    super.update(newRequirements);

    // TODO
  }

  void setListener(
    Function(
      List<ProdLineNode> newNodes,
      List<DirectedEdge> newEdges,
      List<ProdLineNode> removedNodes,
      List<DirectedEdge> removedEdges,
    )
    callback,
  ) {
    _callBackOnChange = callback;
  }

  // Method is public to allow UI to use when displaying tree
  // 'Height' of a node is the length of the longest path from the input nodes
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

  void updateNodesAndDescendants(
    Map<ProdLineNode, ItemIo> nodesAndRequirements, {
    bool updateListeners = false,
  }) {
    var nodeHeights = getNodeHeights(nodesAndRequirements.keys);

    // Only possible if one node is a descendant of another
    if (nodeHeights[0].length != nodesAndRequirements.length) {
      throw const FactorioException(
        'Cannot give requirements to child and parent node',
      );
    }

    var allOrderedNodes = nodeHeights.expand((entry) => entry).toList();

    Map<ItemData, ProdLineNode> disposalNodes = {};
    for (var disposalNode in _nodes.where(
      (node) => node._type == NodeType.disposal,
    )) {
      for (var input in disposalNode.allInputs) {
        disposalNodes[input] = disposalNode;
      }
    }

    // Exists so changes can be rolled back if exception occurs
    Map<ProdLineNode, ItemIo?> oldRequirementsMap = {};
    Map<DirectedEdge, double?> oldAmountMap = {};
    List<ProdLineNode> newDisposalNodes = [];
    List<DirectedEdge> newEdges = [];

    try {
      for (var node in allOrderedNodes) {
        ItemIo requirements;
        if (nodesAndRequirements.containsKey(node)) {
          requirements = nodesAndRequirements[node]!;
        } else {
          requirements = _determineRequirementsFromParents(node);
        }

        oldRequirementsMap[node] = node.requirements;
        for (var child in node.children) {
          oldAmountMap[child] = child.amount;
        }

        _updateNodeAndChildEdges(
          node,
          requirements,
          disposalNodes,
          newDisposalNodes,
          newEdges,
        );
      }

      for (var node in newDisposalNodes) {
        node.update(_determineRequirementsFromParents(node));
      }

      if (newDisposalNodes.isNotEmpty && updateListeners) {
        // This call will ensure that the parent widget is rebuilt
        // Doing so will rebuild all children widgets anyway
        // eliminating the need to manually update all the children
        // TODO - Confirm this is actually the case
        _callBackOnChange!(newDisposalNodes, newEdges, const [], const []);
      } else if (updateListeners) {
        _updateNodeAndChildrenListeners(allOrderedNodes);
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

      for (var newNode in newDisposalNodes) {
        newNode.removeFromGraph();
      }

      rethrow;
    }
  }

  ItemIo _determineRequirementsFromParents(ProdLineNode node) {
    ItemIo requirements = {};
    for (var parent in node.parents) {
      if (parent.amount == null) {
        throw const FactorioException('Parent is not initialised');
      }

      double parentAmount =
          parent.flowDirection == ItemFlowDirection.childToParent
          ? parent.amount!
          : -parent.amount!;

      requirements.update(
        parent.item,
        (existingAmount) => existingAmount + parentAmount,
        ifAbsent: () => parentAmount,
      );
    }

    return requirements;
  }

  void _updateNodeAndChildEdges(
    ProdLineNode node,
    ItemIo newRequirements,
    Map<ItemData, ProdLineNode> disposalNodes,
    List<ProdLineNode> newDisposalNodes,
    List<DirectedEdge> newEdges,
  ) {
    node.update(newRequirements);

    ItemIo io = node.totalIoPerSecond!;
    List<DirectedEdge> allEdges = [...node.parents, ...node.children];

    for (var output in node.allOutputs) {
      double amount = io[output]!;

      double totalRequested = node.parents
          .where((edge) => edge.item == output)
          .map((edge) => edge._amount!)
          .reduce((amount1, amount2) => amount1 + amount2);

      double difference = totalRequested - amount;
      // Account for floating point issues
      bool withinBounds = difference.abs() < totalRequested * 0.01;

      // Create or use existing disposal node if excess production
      if (!withinBounds && difference < 0) {
        throw FactorioException(
          'Could not produce required amount of "$output"',
        );
      } else if (!withinBounds) {
        /*
         * In order
         * Find existing acceptExcess edge
         * If not available, find existing disposal node and create edge
         * If not available, create disposal node and edge
         */
        DirectedEdge? acceptExcessEdge = node.children
            .where(
              (edge) =>
                  edge.item == output &&
                  edge.edgeType == Relationship.acceptExcess,
            )
            .firstOrNull;

        if (acceptExcessEdge != null) {
          acceptExcessEdge._amount = difference;
        } else {
          var disposalNode = disposalNodes[output];

          if (disposalNode == null) {
            disposalNode = ProdLineNode.addToGraph(
              parentGraph: this,
              type: NodeType.disposal,
              line: IoLine(inputs: {output}),
            );

            newDisposalNodes.add(disposalNode);
            disposalNodes[output] = disposalNode;
          }

          acceptExcessEdge = DirectedEdge.addToGraph(
            parentGraph: this,
            item: output,
            parent: node,
            child: disposalNode,
            initialAmount: difference,
            edgeType: Relationship.acceptExcess,
          );

          newEdges.add(acceptExcessEdge);
        }
      }
    }

    for (var input in node.allInputs) {
      // TODO - Account for multiple producers of single item
      DirectedEdge? inputEdge = allEdges
          .where((edge) => edge.item == input)
          .firstOrNull;

      if (inputEdge == null) {
        throw FactorioException('No input provided for item "$input"');
      } else if (inputEdge.edgeType == Relationship.requestItems) {
        inputEdge._amount = io[input]!;
      }
    }
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

  void _updateNodeAndChildrenListeners(List<ProdLineNode> updatedNodes) {
    for (var updatedNode in updatedNodes) {
      updatedNode._callbackOnChange!();
      for (var child in updatedNode.children) {
        child._callbackOnChange!();
      }
    }
  }
}
