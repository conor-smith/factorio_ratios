import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
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
 * A callback only needs to occur when the one component affects the state of another
 * eg. If a node's position is changed, the positions of connected edges
 * will also be updated
 * 
 * If a graph is updated, there is no need to update states of node and edge widgets
 * as a graph update means a full rebuild of all widgets
 * 
 * Only the active graph and it's nodes and edges need to worry about updating state
 */
class BaseGraph extends ProductionLine {
  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _parentOfMap = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _childOfMap = {};

  final Surface? surface;

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};
  ItemIo? _requirements;
  ItemIo? _totalIoPerSecond;

  Function({
    List<ProdLineNode> newNodes,
    List<DirectedEdge> newEdges,
    List<ProdLineNode> removedNodes,
    List<DirectedEdge> removedEdges,
  })?
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

  BaseGraph({this.surface});

  @override
  void update(ItemIo newRequirements) {
    super.update(newRequirements);

    // TODO
  }

  @override
  void reset() {
    for (var node in _nodes) {
      node.reset();
    }

    _totalIoPerSecond = null;
    _requirements = null;
  }

  void setListener(
    Function({
      List<ProdLineNode>? newNodes,
      List<DirectedEdge>? newEdges,
      List<ProdLineNode>? removedNodes,
      List<DirectedEdge>? removedEdges,
    })
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
          requirements = node._determineRequirementsFromParents();
        }

        oldRequirementsMap[node] = node.requirements;
        for (var edge in node.parentOf) {
          oldAmountMap[edge] = edge.amount;
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
        node.update(node._determineRequirementsFromParents());
      }

      if (newDisposalNodes.isNotEmpty && updateListeners) {
        // This call will ensure that the parent widget is rebuilt
        // Doing so will rebuild all children widgets anyway
        // eliminating the need to manually update all the children
        // TODO - Confirm this is actually the case
        _callBackOnChange!(newNodes: newDisposalNodes, newEdges: newEdges);
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

  void _addNewNodeData(ProdLineNode newNode, bool updateListener) {
    if (newNode.nodeType.isIo) {
      _addIo(newNode);
    }

    _nodes.add(newNode);

    _parentOfMap[newNode] = {};
    _childOfMap[newNode] = {};

    if (updateListener) {
      _callBackOnChange!(newNodes: [newNode]);
    }
  }

  void _addNewEdgeData(DirectedEdge newEdge, bool updateListener) {
    _edges.add(newEdge);

    // Add edge to relevant parentOf and childOf entries
    _parentOfMap[newEdge.parent]!.add(newEdge);
    _childOfMap[newEdge.child]!.add(newEdge);

    if (updateListener) {
      _callBackOnChange!(newEdges: [newEdge]);
    }
  }

  void _removeNodeData(ProdLineNode node, bool updateIo, bool updateListener) {
    _nodes.remove(node);

    List<DirectedEdge> edgesToRemove = [];

    // Remove all edges in which this node is parent
    for (var edge in node.parentOf) {
      edgesToRemove.add(edge);
      _childOfMap[edge.child]!.remove(edge);
    }
    // Remove all edges in which this node is child
    for (var edge in node.childOf) {
      edgesToRemove.add(edge);
      _parentOfMap[edge.parent]!.remove(edge);
    }

    // Removed parentOf and childOf entries
    _parentOfMap.remove(node);
    _childOfMap.remove(node);

    _edges.removeAll(edgesToRemove);

    // Update IO if necessary
    if (updateIo && node.nodeType.isIo) {
      _removeIo(node);
    }

    if (updateListener) {
      _callBackOnChange!(removedNodes: [node], removedEdges: edgesToRemove);
    }
  }

  void _removeEdgeData(DirectedEdge edge, bool updateListener) {
    _edges.remove(edge);

    _parentOfMap[edge.parent]!.remove(edge);
    _childOfMap[edge.child]!.remove(edge);

    if (updateListener) {
      _callBackOnChange!(removedEdges: [edge]);
    }
  }

  void _addIo(ProdLineNode newIoNode) {
    if (newIoNode.nodeType == NodeType.output) {
      // Verify that output does not already exist
      if (newIoNode.allInputs.every(
        (nodeInput) => !_allOutputs.contains(nodeInput),
      )) {
        throw const FactorioException('Duplicate IO added');
      } else {
        _allOutputs.addAll(newIoNode.allInputs);
      }
    } else if (newIoNode.nodeType == NodeType.input) {
      // Verify input does not already exist
      if (newIoNode.allOutputs.every(
        (nodeOutput) => !_allInputs.contains(nodeOutput),
      )) {
        throw const FactorioException('Duplicate IO added');
      } else {
        _allInputs.addAll(newIoNode.allOutputs);
      }
    }
  }

  void _removeIo(ProdLineNode oldIoNode) {
    if (oldIoNode.nodeType == NodeType.output) {
      _allOutputs.removeAll(oldIoNode.allInputs);
    } else if (oldIoNode.nodeType == NodeType.input) {
      _allInputs.removeAll(oldIoNode.allOutputs);
    }
  }

  // Calls .update(...) a single node according to requirements
  // Then updates all child edge amounts
  void _updateNodeAndChildEdges(
    ProdLineNode node,
    ItemIo newRequirements,
    Map<ItemData, ProdLineNode> disposalNodes,
    List<ProdLineNode> newDisposalNodes,
    List<DirectedEdge> newEdges,
  ) {
    node.update(newRequirements);

    ItemIo io = node.totalIoPerSecond!;

    for (var output in node.allOutputs) {
      double amount = io[output]!;

      double totalRequested = node.childOf
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
        DirectedEdge? acceptExcessEdge = node.parentOf
            .where(
              (edge) =>
                  edge.item == output &&
                  edge.edgeType == Relationship.acceptExcess,
            )
            .firstOrNull;

        if (acceptExcessEdge != null) {
          // acceptExcess edge and disposal node already exist
          acceptExcessEdge._amount = difference;
        } else {
          // Check if a disposal node exists for this output
          var disposalNode = disposalNodes[output];

          if (disposalNode == null) {
            // No disposal node exists. Create new one
            disposalNode = ProdLineNode.addToGraph(
              parentGraph: this,
              type: NodeType.disposal,
              line: IoLine(inputs: {output}),
            );

            newDisposalNodes.add(disposalNode);
            disposalNodes[output] = disposalNode;
          }

          // Create new edge between this node and disposal node
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
      DirectedEdge? inputEdge = [
        ...node.parentOf,
        ...node.childOf,
      ].where((edge) => edge.item == input).firstOrNull;

      if (inputEdge == null) {
        throw FactorioException('No input provided for item "$input"');
      } else if (inputEdge.edgeType == Relationship.requestItems) {
        inputEdge._amount = io[input]!;
      }
    }
  }

  // Returns the maximum height
  int _getDescendantsHeight(
    ProdLineNode node,
    Map<ProdLineNode, int> heightMap,
    int currentHeight,
  ) {
    int existingHeight = heightMap[node] ?? -1;
    if (currentHeight > existingHeight) {
      heightMap[node] = currentHeight;
      int maxHeight = currentHeight;

      for (var edge in node.parentOf) {
        int newMax = _getDescendantsHeight(
          edge.child,
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
      for (var edge in updatedNode.parentOf) {
        edge._callbackOnChange!();
      }
    }
  }
}
