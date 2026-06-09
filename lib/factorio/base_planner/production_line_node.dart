import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

class ProductionLineNode
    implements BasePlannerElement<NodeState, NodeEvent>, Node {
  final BasePlanner basePlanner;
  late final Function(Function) newSnapshotFunction;

  @override
  final int id;

  @override
  final Graph parentGraph;
  @override
  NodeGeometry get nodeGeometry => _state.nodeGeometry;
  @override
  Set<Edge> get parents => _state.parents;
  @override
  Set<Edge> get children => _state.children;
  @override
  ProductionLineIo? get io => _state.io;

  final NodeType nodeType;

  final EventNotifier<NodeEvent> _notifier = EventNotifier();
  late NodeState _state;

  // For convenience
  ItemAmounts? get requiredInput => _state.requiredInput;
  ItemAmounts? get requiredOutput => _state.requiredOutput;
  ProductionLine get productionLine => _state.productionLine;

  ProductionLineNode({
    required this.basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
  }) : id = BasePlannerElement.generateId() {
    // TODO: verification
    _state = NodeState(productionLine: productionLine);
    basePlanner.initialiseProdLineNode(this);

    basePlanner.getGraphStateBuilder(parentGraph).addNode(this);
  }

  @override
  NodeState get state => _state;
  @override
  set state(NodeState state) {
    basePlanner.throwIfMutationNotPermitted();
    _state = state;
  }

  @override
  void addCallback(Function(NodeEvent event) callback) =>
      _notifier.addCallback(callback);
  @override
  void clearCallbacks() => _notifier.clearCallbacks();
  @override
  void notifyListeners(NodeEvent event) => _notifier.notifyListeners(event);

  @override
  void notifyListenerOfStateChange(
    ElementState oldState,
    ElementState newState,
  ) {
    // TODO: implement notifyListenerOfStateChange
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class NodeState implements ElementState {
  final ItemAmounts? requiredInput;
  final ItemAmounts? requiredOutput;

  final ProductionLine productionLine;
  final ProductionLineIo? io;

  final NodeGeometry nodeGeometry;

  final Set<Edge> parents;
  final Set<Edge> children;

  NodeState({
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

class NodeStateBuilder implements Builder<NodeState>, NodeState {
  final BasePlanner _basePlanner;

  ItemAmounts? _requiredInput;
  ItemAmounts? _requiredOutput;

  ProductionLine _productionLine;

  ProductionLineIo? _io;
  bool _ioUpdate = false;

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
  bool get ioUpdate => _ioUpdate;

  @override
  NodeGeometry get nodeGeometry => _nodeGeometry;

  @override
  late final Set<Edge> parents = UnmodifiableSetView(parents);
  @override
  late final Set<Edge> children = UnmodifiableSetView(children);

  NodeStateBuilder.from(ProductionLineNode node)
    : _basePlanner = node.basePlanner,
      _requiredInput = node.requiredInput,
      _requiredOutput = node.requiredOutput,
      _productionLine = node.productionLine,
      _io = node.io,
      _nodeGeometry = node.nodeGeometry,
      _parents = Set.from(node.parents),
      _children = Set.from(node.children);

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
    if (io != null) {
      _io = null;
      _ioUpdate = true;
    }
  }

  void calculateIo({
    ItemAmounts inputConstraints = const {},
    ItemAmounts outputConstraints = const {},
  }) {
    _ioUpdate = true;
    _io = productionLine.calculate(
      inputConstraints: inputConstraints,
      outputConstraints: outputConstraints,
    );
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

      calculateIo(
        inputConstraints: inputConstraints,
        outputConstraints: outputConstraints,
      );
    }
  }

  ItemIo updateChildrenAndReturnUnfulfilledIo() {
    // TODO: optimise
    var io = _io;
    if (io == null) {
      for (var child in _children) {
        _basePlanner.getEdgeStateBuilder(child).clearAmount();
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

      var remainingOutput = io.netOutput.map(
        (item, amount) => MapEntry(item, amount - (consumedOutput[item] ?? 0)),
      );
      var unfulfilledInput = io.netInput.map(
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
          _basePlanner.getEdgeStateBuilder(aeEdge).updateAmount(removedOutput);
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
          _basePlanner.getEdgeStateBuilder(riEdge).updateAmount(fulfilledInput);
        }

        return amount - totalFulfilledInput;
      });

      return ItemIo(inputs: unfulfilledInput, outputs: remainingOutput);
    }
  }

  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  void addParent(Edge parent) => _parents.add(parent);
  void removeParent(Edge parent) => _parents.remove(parent);

  void addChild(Edge child) => _children.add(child);
  void removeChild(Edge child) => _children.remove(child);

  @override
  NodeState build() => NodeState(
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
