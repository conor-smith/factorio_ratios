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
    _state = NodeState(node: this, productionLine: productionLine);
    basePlanner.initialiseNode(this);

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
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(NodeEvent event) callback) =>
      _notifier.eventCallback = callback;
  @override
  void clearCallback() => _notifier.clearCallback();
  @override
  void notifyListener(NodeEvent event) => _notifier.notifyListener(event);

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
  final ProductionLineNode _node;

  final ItemAmounts? requiredInput;
  final ItemAmounts? requiredOutput;

  final ProductionLine productionLine;
  final ProductionLineIo? io;

  final NodeGeometry nodeGeometry;

  final Set<Edge> parents;
  final Set<Edge> children;

  NodeState({
    required ProductionLineNode node,
    ItemAmounts? requiredInput,
    ItemAmounts? requiredOutput,
    required this.productionLine,
    this.io,
    this.nodeGeometry = NodeGeometry.uninitialised,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
  }) : _node = node,
       requiredInput = requiredInput != null
           ? Map.unmodifiable(requiredInput)
           : null,
       requiredOutput = requiredOutput != null
           ? Map.unmodifiable(requiredOutput)
           : null,
       parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children) {
    // TODO: Validation
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class NodeStateBuilder implements Builder<NodeState>, NodeState {
  @override
  final ProductionLineNode _node;

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

  factory NodeStateBuilder.from(NodeState state) {
    if (state is NodeStateBuilder) {
      return state;
    } else {
      return NodeStateBuilder._from(state);
    }
  }

  NodeStateBuilder._from(NodeState state)
    : _node = state._node,
      _requiredInput = state.requiredInput,
      _requiredOutput = state.requiredOutput,
      _productionLine = state.productionLine,
      _io = state.io,
      _nodeGeometry = state.nodeGeometry,
      _parents = Set.from(state.parents),
      _children = Set.from(state.children);

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
    _io = null;
  }

  void calculateIo({
    ItemAmounts inputConstraints = const {},
    ItemAmounts outputConstraints = const {},
  }) {
    _io = productionLine.calculate(
      inputConstraints: inputConstraints,
      outputConstraints: outputConstraints,
    );
  }

  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  void addParent(Edge parent) => _parents.add(parent);
  void removeParent(Edge parent) => _parents.remove(parent);

  void addChild(Edge child) => _children.add(child);
  void removeChild(Edge child) => _children.remove(child);

  @override
  NodeState build() => NodeState(
    node: _node,
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
  // TODO
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
