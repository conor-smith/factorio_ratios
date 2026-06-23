part of 'production_line_node.dart';

abstract class ProdLineNodeState {
  ItemIo? get requirements;

  ProductionLine get productionLine;
  ProductionLineIo? get io;

  NodeGeometryImpl get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;

  Map<InGameItem, List<Edge>> get outputEdges;
  Map<InGameItem, List<Edge>> get inputEdges;
}

class ProdLineNodeStateImpl implements ProdLineNodeState, ToJson {
  @override
  final ItemIo? requirements;

  @override
  final ProductionLine productionLine;
  @override
  final ProductionLineIo? io;

  @override
  final NodeGeometryImpl nodeGeometry;

  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  @override
  late final Map<InGameItem, List<Edge>> outputEdges =
      NodeElement.calculateOutputEdges(parents, children);
  @override
  late final Map<InGameItem, List<Edge>> inputEdges =
      NodeElement.calculateInputEdges(parents, children);

  ProdLineNodeStateImpl._initial({
    required this.productionLine,
    required this.nodeGeometry,
  }) : requirements = null,
       io = null,
       parents = const {},
       children = const {};

  ProdLineNodeStateImpl._(
    ProdLineNode node, {
    this.requirements,
    required this.productionLine,
    required this.io,
    required this.nodeGeometry,
    required Iterable<Edge> parents,
    required Iterable<Edge> children,
  }) : parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children) {
    for (var parent in this.parents) {
      if (parent.child != node) {
        throw NodeException('Edge $parent is not a parent of node $node');
      }
    }

    for (var child in this.children) {
      if (child.parent != node) {
        throw NodeException('Edge $child is not a parent of node $node');
      }
    }

    outputEdges.forEach((item, itemEdges) {
      if(!productionLine.outputItems.contains(item)) {
        throw NodeException('Node $node cannot output item $item');
      }

      var aeTotalPercentage = itemEdges
          .where((edge) => edge.edgeType == EdgeType.acceptExcess)
          .map((edge) => edge.percentage)
          .fold(0.0, (perc1, perc2) => perc1 + perc2);

      // Round to nearest 0.01 before checking
      if ((aeTotalPercentage * 100).floor() > 100) {
        throw NodeException(
          'Ouput AcceptExcess edges for item $item on node $node sum up to value $aeTotalPercentage',
        );
      }
    });

    inputEdges.forEach((item, itemEdges) {
      if(!productionLine.inputItems.contains(item)) {
        throw NodeException('Node $node cannot consume item $item');
      }

      var reTotalPercentage = itemEdges
          .where((edge) => edge.edgeType == EdgeType.requestItems)
          .map((edge) => edge.percentage)
          .fold(0.0, (perc1, perc2) => perc1 + perc2);

      // Round to nearest 0.01 before checking
      if ((reTotalPercentage * 100).floor() > 100) {
        throw NodeException(
          'Ouput AcceptExcess edges for item $item on node $node sum up to value $reTotalPercentage',
        );
      }
    });
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class ProdLineNodeStateBuilder
    implements NodeStateBuilder<ProdLineNodeStateImpl>, ProdLineNodeState {
  final ProdLineNode _node;

  bool _removingSelf = false;
  ItemIo? _requirements;
  ProductionLine _productionLine;
  ProductionLineIo? _io;
  NodeGeometryImpl _nodeGeometry;
  final Set<Edge> _parents;
  final Set<Edge> _children;

  @override
  ItemIo? get requirements => _requirements;
  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIo? get io => _io;
  @override
  NodeGeometryImpl get nodeGeometry => _nodeGeometry;
  @override
  late final Set<Edge> parents = UnmodifiableSetView(parents);
  @override
  late final Set<Edge> children = UnmodifiableSetView(children);

  // TODO - Cache these
  @override
  Map<InGameItem, List<Edge>> get inputEdges =>
      NodeElement.calculateInputEdges(parents, children);
  @override
  Map<InGameItem, List<Edge>> get outputEdges =>
      NodeElement.calculateOutputEdges(parents, children);

  ProdLineNodeStateBuilder._from(this._node)
    : _requirements = _node._state.requirements,
      _productionLine = _node._state.productionLine,
      _io = _node._state.io,
      _nodeGeometry = _node._state.nodeGeometry,
      _parents = Set.from(_node._state.parents),
      _children = Set.from(_node._state.children) {
    _node._basePlanner.getSnapshotBuilder().addToSnapsnot(_node, this);
  }

  @override
  void addSelf() {
    _node.parentGraph.getStateBuilder().addProdLineNode(_node);
  }

  @override
  void removeSelf() {
    if (!_removingSelf) {
      _removingSelf = true;
      _node._basePlanner.getSnapshotBuilder().removeFromSnapshot(_node);

      var edgesToRemove = [...parents, ...children];

      _parents.clear();
      _children.clear();

      for (var edge in edgesToRemove) {
        edge.getStateBuilder().removeSelf();
      }
    }
  }

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  void addParent(Edge parent) => _parents.add(parent);
  @override
  void addChild(Edge child) => _children.add(child);

  @override
  void removeParent(Edge parent) {
    if (!_removingSelf) {
      parent.getStateBuilder().removeSelf();
      _parents.remove(parent);
    }
  }

  @override
  void removeChild(Edge child) {
    if (!_removingSelf) {
      child.getStateBuilder().removeSelf();
      _children.remove(child);
    }
  }

  void updateRequirements(ItemIo requirements) => _requirements = requirements;
  void clearRequirements() => _requirements = null;

  void updateProductionLineAndClearIo(ProductionLine productionLine) {
    _productionLine = productionLine;
    clearIo();
  }

  void clearIo() {
    if (_io != null) {
      _io = null;
      _node.parentGraph.getStateBuilder().clearIo();
    }
  }

  void calculateIo(ItemIo constraints) {
    _io = productionLine.calculate(constraints);
    _node.parentGraph.getStateBuilder().clearIo();
  }

  void calculateIoFromParentEdges() {
    ItemAmounts inputConstraints = {};
    ItemAmounts outputConstraints = {};

    for (var parent in _parents) {
      var newAmount = parent.amount ?? 0;
      switch (parent.edgeType) {
        case EdgeType.requestItems:
          outputConstraints.update(
            parent.item,
            (amount) => amount + newAmount,
            ifAbsent: () => newAmount,
          );
        case EdgeType.acceptExcess:
          inputConstraints.update(
            parent.item,
            (amount) => amount + newAmount,
            ifAbsent: () => newAmount,
          );
      }

      calculateIo(ItemIo(inputs: inputConstraints, outputs: outputConstraints));
    }
  }

  ItemIo updateChildrenAndReturnUnfulfilledIo() {
    // TODO: optimise
    var io = _io;
    if (io == null) {
      for (var child in _children) {
        child.getStateBuilder().clearAmount();
      }

      return ItemIo();
    } else {
      ItemAmounts consumedOutput = {};
      ItemAmounts providedInput = {};

      for (var parent in _parents) {
        var parentAmount = parent.amount ?? 0;

        switch (parent.edgeType) {
          case EdgeType.requestItems:
            consumedOutput.update(
              parent.item,
              (amount) => amount + parentAmount,
              ifAbsent: () => parentAmount,
            );

          case EdgeType.acceptExcess:
            providedInput.update(
              parent.item,
              (amount) => amount + parentAmount,
              ifAbsent: () => parentAmount,
            );
        }
      }

      var remainingOutput = io.io.outputs.map(
        (item, amount) => MapEntry(item, amount - (consumedOutput[item] ?? 0)),
      );
      var unfulfilledInput = io.io.inputs.map(
        (item, amount) => MapEntry(item, amount - (providedInput[item] ?? 0)),
      );

      Map<InGameItem, Map<EdgeType, List<Edge>>> itemToChildMap = {};
      for (var child in _children) {
        itemToChildMap.update(
          child.item,
          (edgeTypeMap) => edgeTypeMap
            ..update(
              child.edgeType,
              (edges) => edges..add(child),
              ifAbsent: () => [child],
            ),
          ifAbsent: () => {
            child.edgeType: [child],
          },
        );
      }

      remainingOutput.updateAll((item, amount) {
        double totalRemovedOutput = 0;
        List<Edge> acceptExcessEdges =
            itemToChildMap[item]?[EdgeType.acceptExcess] ?? const [];

        for (var aeEdge in acceptExcessEdges) {
          var removedOutput = amount * aeEdge.percentage;
          totalRemovedOutput += removedOutput;
          aeEdge.getStateBuilder().updateAmount(removedOutput);
        }

        return amount - totalRemovedOutput;
      });

      unfulfilledInput.updateAll((item, amount) {
        double totalFulfilledInput = 0;
        List<Edge> requestItemsEdges =
            itemToChildMap[item]?[EdgeType.requestItems] ?? const [];

        for (var riEdge in requestItemsEdges) {
          var fulfilledInput = amount * riEdge.percentage;
          totalFulfilledInput += fulfilledInput;
          riEdge.getStateBuilder().updateAmount(fulfilledInput);
        }

        return amount - totalFulfilledInput;
      });

      return ItemIo(inputs: unfulfilledInput, outputs: remainingOutput);
    }
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl._(
    _node,
    requirements: _requirements,
    productionLine: _productionLine,
    io: _io,
    nodeGeometry: nodeGeometry,
    parents: _parents,
    children: _children,
  );
}
