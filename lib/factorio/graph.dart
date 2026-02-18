import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:logging/logging.dart';

part 'graph/node_and_edge.dart';

enum NodeType { resource, input, output, productionLine }

enum ItemFlowDirection { parentToChild, childToParent }

enum EdgeType { requestItems, acceptExcess }

const Set<NodeType> producerTypes = const {
  NodeType.input,
  NodeType.resource,
  NodeType.productionLine,
};

class PlanetaryBase extends ProductionLine {
  /*
   * TODO
   * Handle excess items and disposal nodes
   * Handle multiple nodes with the same output
   * Handle output nodes requiring rocket launches
   */
  static final Logger _logger = Logger('Planetary base');

  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};
  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};
  Map<ItemData, double> _totalIoPerSecond = const {};

  final Map<ProdLineNode, Set<DirectedEdge>> _parents = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _children = {};

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  @override
  Map<ItemData, double> get totalIoPerSecond => _totalIoPerSecond;
  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);

  @override
  void update(Map<ItemData, double> requirements) {
    // TODO - Account for required inputs
    var outputNodes = nodes
        .where((node) => node.type == NodeType.output)
        .toSet();
    var inputNodes = nodes.where((node) => node.type == NodeType.input).toSet();

    requirements.forEach((itemD, amount) {
      if (amount <= 0) {
        throw const FactorioException('Cannot handle minimum input');
      } else if (!allOutputs.contains(itemD)) {
        throw FactorioException('Item "$itemD" is not an output of this base');
      }
    });

    requirements.forEach((itemD, amount) {
      if (amount > 0) {
        outputNodes
                .firstWhere((node) => node._requirements.containsKey(itemD))
                ._requirements[itemD] =
            -amount;
      }
    });

    _updateNodeAndChildrenOutputs(outputNodes);

    Map<ItemData, double> totalIo = {};

    for (var node in [...outputNodes, ...inputNodes]) {
      node.requirements.forEach((itemD, amount) {
        totalIo.update(
          itemD,
          (oldAmount) => oldAmount - amount,
          ifAbsent: () => -amount,
        );
      });
    }

    _totalIoPerSecond = Map.unmodifiable(totalIo);
  }

  GraphUpdates addOutputNode(Set<ItemData> itemsToOutput) {
    var updates = GraphUpdates();
    for (var itemD in itemsToOutput) {
      if (!_allOutputs.contains(itemD)) {
        var newNode = ProdLineNode._addToGraph(
          parentGraph: this,
          type: NodeType.output,
          initialRequirements: {itemD: -1},
          line: MagicLine(initialIo: {itemD: -1}),
        );

        _allOutputs.add(itemD);

        var otherUpdates = _updateEdgesForNode(newNode);

        updates.newNodes.add(newNode);
        updates.newNodes.addAll(otherUpdates.newNodes);
        updates.newEdges.addAll(otherUpdates.newEdges);
      }
    }

    return updates;
  }

  GraphUpdates _updateEdgesForNode(ProdLineNode updatedNode) {
    // TODO - Handle nodes that lose children, not just gain
    // TODO - Handle excess output and disposal nodes
    var updates = GraphUpdates();

    for (var itemD in updatedNode.allInputs) {
      if (!_children[updatedNode]!.any(
        (edge) =>
            edge._flowDirection == ItemFlowDirection.childToParent &&
            edge.item == itemD,
      )) {
        ProdLineNode childNode;
        var existingNode = _nodes
            .where(
              (node) =>
                  producerTypes.contains(node.type) &&
                  node.allOutputs.contains(itemD),
            )
            .firstOrNull;
        if (existingNode != null) {
          childNode = existingNode;
        } else {
          childNode = ProdLineNode._addToGraph(
            parentGraph: this,
            type: NodeType.resource,
            initialRequirements: {itemD: 1},
            line: MagicLine(initialIo: {itemD: 1}),
          );

          updates.newNodes.add(childNode);
        }

        var newEdge = DirectedEdge._addToGraph(
          parentGraph: this,
          parent: updatedNode,
          child: childNode,
          edgeType: EdgeType.requestItems,
          flowDirection: ItemFlowDirection.childToParent,
          item: itemD,
        );

        updates.newEdges.add(newEdge);

        _checkForCycle(childNode, {updatedNode});
      }
    }

    return updates;
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

  void _updateNodeAndChildrenOutputs(Set<ProdLineNode> nodes) {
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
          node.update(node._requirements);
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

class GraphUpdates {
  Set<ProdLineNode> newNodes = {};
  Set<DirectedEdge> newEdges = {};
}
