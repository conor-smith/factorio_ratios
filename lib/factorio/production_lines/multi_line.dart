part of '../production_line.dart';

/*
 * Rules for this production line are as follows
 * I/O is given by 1 or more I/O nodes
 * I/O nodes contain an InfiniteLine
 * A node containing an InfiniteLine is not necessarily I/O (eg. Could represent a resource patch)
 * Itemflow is unidirectional - all flow begins at input and terminates at output
 * There can be an arbitrary number of production line nodes between input and output nodes
 * Circular flows are not permitted
 * Every item may only have 1 producer
 */
class PlanetaryBase extends ProductionLine {
  // TODO
  // Handle recipes with multiple outputs
  // Figure out a better way to represent edges / item flows
  // Only update nodes that need to be updated
  final Map<ItemData, double> _ioPerSecond = {};
  @override
  late final Map<ItemData, double> ioPerSecond = UnmodifiableMapView(
    _ioPerSecond,
  );

  final List<ProdLineNode> _nodes = [];
  final List<ItemFlow> _itemFlows = [];
  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<ItemFlow> itemFlows = UnmodifiableListView(_itemFlows);

  // Does result in some duplication, but makes lookups much quicker
  final Map<ProdLineNode, Set<ItemFlow>> _parents = {};
  final Map<ProdLineNode, Set<ItemFlow>> _children = {};

  final Map<ItemData, ProdLineNode> _itemProducers = {};
  final Map<ItemData, ProdLineNode> _outputNodes = {};

  ProdLineNode getOrCreateOutputNode(ItemData itemToOutput) {
    late ProdLineNode node;
    if (_outputNodes.containsKey(itemToOutput)) {
      node = _outputNodes[itemToOutput]!;
    } else {
      node = ProdLineNode._addToGraph(this, Resource(itemToOutput, -1));
      _outputNodes[itemToOutput] = node;
      _updateNodeRelationships(node);
    }

    node._isIo = true;
    return node;
  }

  void _updateNodeRelationships(ProdLineNode updatedNode) {
    updatedNode._productionLine.ioPerSecond.forEach((itemD, amount) {
      if (amount < 0 &&
          updatedNode.children
              .where((flow) => flow.itemData == itemD)
              .isEmpty) {
        late ProdLineNode childNode;
        if (_itemProducers.containsKey(itemD)) {
          childNode = _itemProducers[itemD]!;
        } else {
          childNode = ProdLineNode._addToGraph(this, Resource(itemD, 1));
          _itemProducers[itemD] = childNode;
        }

        ItemFlow._addToGraph(this, updatedNode, childNode, itemD);
      }
    });
  }

  @override
  void update(Map<ItemData, double> requirements) {
    Map<ProdLineNode, ItemData> filteredOutputNodes = {};

    for (var itemD in requirements.keys) {
      if (!_outputNodes.containsKey(itemD)) {
        throw FactorioException(
          'No output node exists for item "${itemD.item.name}"',
        );
      } else {
        ProdLineNode outputNode = _outputNodes[itemD]!;
        filteredOutputNodes[outputNode] = itemD;
      }
    }

    // Perform depth first traversal to determine order of updates
    // Also identifies circular dependencies and orphans
    Map<ProdLineNode, int> nodesWithOrder = {};
    Set<ProdLineNode> parents = {};

    for (var outputNode in filteredOutputNodes.keys) {
      for (var directChild in outputNode.children.map((flow) => flow.child)) {
        _traverseChildNodes(nodesWithOrder, parents, directChild, 1);
      }
    }

    filteredOutputNodes.forEach((outputNode, itemD) {
      outputNode._productionLine.update({itemD: requirements[itemD]!});
      _updateChildFlows(outputNode);
    });

    (nodesWithOrder.entries.toList()
          ..sort((entry1, entry2) => entry1.value.compareTo(entry2.value)))
        .map((entry) => entry.key)
        .forEach((node) {
          Map<ItemData, double> nodeRequirements = {};

          for (var flow in node.parents) {
            nodeRequirements.update(
              flow.itemData,
              (currentValue) => currentValue += flow._amount,
              ifAbsent: () => flow._amount,
            );
          }

          node._productionLine.update(nodeRequirements);

          _updateChildFlows(node);
        });
  }

  void _traverseChildNodes(
    Map<ProdLineNode, int> allNodesOrder,
    Set<ProdLineNode> parents,
    ProdLineNode node,
    int order,
  ) {
    if (parents.contains(node)) {
      // Default implementation of set is LinkedHashSet, so order is preserved
      String trace = parents
          .map((node) => node.name)
          .reduce((parent, child) => '$parent -> $child');
      throw FactorioException(
        'Circular dependency detected: $trace -> ${node.name}',
      );
    }

    int? currentOrder = allNodesOrder[node];
    if (currentOrder == null || currentOrder < order) {
      allNodesOrder[node] = order;
      parents.add(node);

      for (var child in node.children.map((flow) => flow.child)) {
        _traverseChildNodes(allNodesOrder, parents, child, order + 1);
      }

      parents.remove(node);
    }
  }

  void _updateChildFlows(ProdLineNode node) {
    node._productionLine.ioPerSecond.forEach((itemd, amount) {
      if (amount < 0) {
        ItemFlow childFlow = node.children.firstWhere(
          (flow) => flow.itemData == itemd,
        );
        childFlow._amount = amount;
      }
    });
  }

  @override
  String get name => 'Graph';
}

class ProdLineNode {
  final PlanetaryBase parentGraph;
  ProductionLine _productionLine;
  bool _isIo = false;

  late final Set<ItemFlow> parents = UnmodifiableSetView(
    parentGraph._parents[this]!,
  );
  late final Set<ItemFlow> children = UnmodifiableSetView(
    parentGraph._children[this]!,
  );

  ProdLineNode._addToGraph(this.parentGraph, this._productionLine) {
    parentGraph._nodes.add(this);
    parentGraph._parents[this] = {};
    parentGraph._children[this] = {};
  }

  ProductionLine get productionLine => _productionLine;

  String get name => _productionLine.name;
}

class ItemFlow {
  final PlanetaryBase parentBase;
  final ProdLineNode parent;
  final ProdLineNode child;
  final ItemData itemData;
  double _amount = 0;

  ItemFlow._addToGraph(
    this.parentBase,
    this.parent,
    this.child,
    this.itemData,
  ) {
    parentBase._itemFlows.add(this);
    parentBase._parents.update(parent, (children) => children..add(this));
    parentBase._children.update(child, (parents) => parents..add(this));
  }

  double get amount => _amount;
}
