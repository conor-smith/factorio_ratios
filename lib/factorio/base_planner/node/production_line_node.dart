part of 'node.dart';

class ProdLineNode implements NodeElement<ProdLineNodeState, NodeEvent> {
  final BasePlanner _basePlanner;

  @override
  final int id;

  @override
  final Graph parentGraph;
  @override
  final NodeType nodeType;

  // For convenience
  ItemAmounts? get requiredInput => _state.requiredInput;
  ItemAmounts? get requiredOutput => _state.requiredOutput;
  @override
  ProductionLine get productionLine => _state.productionLine;
  @override
  NodeGeometry get nodeGeometry => state.nodeGeometry;
  @override
  Set<Edge> get parents => state.parents;
  @override
  Set<Edge> get children => state.children;
  @override
  ProductionLineIo? get io => state.io;
  @override
  Set<InGameItem> get inputItems => state.productionLine.inputItems;
  @override
  Set<InGameItem> get outputItems => state.productionLine.outputItems;

  final EventNotifier<NodeEvent> _notifier = EventNotifierImpl();
  ProdLineNodeState _state;
  ProdLineNodeStateBuilder? _builder;

  ProdLineNode({
    required BasePlanner basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
  }) : _basePlanner = basePlanner,
       id = BasePlannerElement.generateId(),
       _state = ProdLineNodeState._(productionLine: productionLine) {
    var builder = ProdLineNodeStateBuilder._from(this);

    _builder = builder;
    _basePlanner.getSnapshotBuilder().addToSnapsnot(this, builder);

    var parentGraphStateBuilder = parentGraph.getStateBuilder();
    parentGraphStateBuilder
      ..addNode(this)
      ..clearIo();

    if (nodeType.isIo) {
      parentGraphStateBuilder.clearIoNodeItems();
    }
  }

  @override
  ProdLineNodeState get state => _builder ?? _state;
  @override
  set state(ProdLineNodeState state) {
    _basePlanner.throwIfMutationNotPermitted();

    // Validate state
    _state = state;
  }

  @override
  ProdLineNodeStateBuilder getStateBuilder() {
    if (_builder != null) {
      var builder = ProdLineNodeStateBuilder._from(this);
      _basePlanner.getSnapshotBuilder().addToSnapsnot(this, builder);
      _builder = builder;
    }

    return _builder!;
  }

  @override
  void addListener(Object listener, Function(NodeEvent event) callback) =>
      _notifier.addListener(listener, callback);
  @override
  void removeListener(Object listener) => _notifier.removeListener(listener);
  @override
  void clearListeners() => _notifier.clearListeners();
  @override
  void notifyListeners(NodeEvent event) => _notifier.notifyListeners(event);

  @override
  void notifyListenersOfStateChange(
    ProdLineNodeState oldState,
    ProdLineNodeState newState,
  ) {
    // TODO: implement notifyListenerOfStateChange
    throw UnimplementedError();
  }

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometry nodeGeometry) {
    // TODO: implement notifyListenersOfGeometryUpdate
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class ProdLineNodeState implements ToJson {
  final ItemAmounts? requiredInput;
  final ItemAmounts? requiredOutput;

  final ProductionLine productionLine;
  final ProductionLineIo? io;

  final NodeGeometry nodeGeometry;

  final Set<Edge> parents;
  final Set<Edge> children;

  ProdLineNodeState._({
    ItemAmounts? requiredInput,
    ItemAmounts? requiredOutput,
    required this.productionLine,
    this.io,
    this.nodeGeometry = NodeGeometry.uninitialised,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
  }) : requiredInput = requiredInput != null
           ? Map.unmodifiable(requiredInput)
           : null,
       requiredOutput = requiredOutput != null
           ? Map.unmodifiable(requiredOutput)
           : null,
       parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class ProdLineNodeStateBuilder
    implements NodeStateBuilder<ProdLineNodeState>, ProdLineNodeState {
  final ProdLineNode _node;

  ItemAmounts? _requiredInput;
  ItemAmounts? _requiredOutput;

  ProductionLine _productionLine;

  ProductionLineIo? _io;

  NodeGeometry _nodeGeometry;

  final Set<Edge> _parents;
  final Set<Edge> _children;

  @override
  ItemAmounts? get requiredInput => _requiredInput;
  @override
  ItemAmounts? get requiredOutput => _requiredOutput;

  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIo? get io => _io;

  @override
  NodeGeometry get nodeGeometry => _nodeGeometry;

  @override
  late final Set<Edge> parents = UnmodifiableSetView(parents);
  @override
  late final Set<Edge> children = UnmodifiableSetView(children);

  ProdLineNodeStateBuilder._from(this._node)
    : _requiredInput = _node.requiredInput,
      _requiredOutput = _node.requiredOutput,
      _productionLine = _node.productionLine,
      _io = _node.io,
      _nodeGeometry = _node.nodeGeometry,
      _parents = Set.from(_node.parents),
      _children = Set.from(_node.children);

  void updateRequirements({
    ItemAmounts? requiredInput,
    ItemAmounts? requiredOutput,
  }) {
    _requiredInput = requiredInput != null
        ? Map.unmodifiable(requiredInput)
        : null;
    _requiredOutput = requiredOutput != null
        ? Map.unmodifiable(requiredOutput)
        : null;
  }

  void clearRequirements() => updateRequirements();

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

      var remainingOutput = io.netIo.outputs.map(
        (item, amount) => MapEntry(item, amount - (consumedOutput[item] ?? 0)),
      );
      var unfulfilledInput = io.netIo.inputs.map(
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
  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  void addParent(Edge parent) => _parents.add(parent);
  @override
  void removeParent(Edge parent) => _parents.remove(parent);

  @override
  void addChild(Edge child) => _children.add(child);
  @override
  void removeChild(Edge child) => _children.remove(child);

  @override
  ProdLineNodeState build() => ProdLineNodeState._(
    requiredInput: _requiredInput,
    requiredOutput: _requiredOutput,
    productionLine: _productionLine,
    io: _io,
    nodeGeometry: nodeGeometry,
    parents: _parents,
    children: _children,
  );

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class NodeEvent {
  NodeEvent.geometryOp(NodeGeometry nodeGeometry) {
    throw UnimplementedError();
  }
}

enum NodeType {
  consumer(false),
  producer(false),
  input(true),
  output(true),
  resource(false),
  disposal(false),
  productionLine(false);

  final bool isIo;

  const NodeType(this.isIo);
}
