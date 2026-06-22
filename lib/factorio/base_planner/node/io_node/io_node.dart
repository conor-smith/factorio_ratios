import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

class IoNode
    with EventNotifier<NodeEvent>
    implements NodeElement<IoNodeState, NodeEvent>, ProductionLine<IoNodeIo> {
  final BasePlanner _basePlanner;

  @override
  final Graph parentGraph;
  @override
  final NodeType nodeType;

  final InGameItem ioItem;

  @override
  final Set<InGameItem> inputItems;
  @override
  Set<InGameItem> get outputItems => inputItems;

  @override
  Icon? get icon => ioItem.icon;
  @override
  final ItemIo? ioRatios;
  @override
  String get name => state.name;
  @override
  ProductionLineType get productionLineType => ProductionLineType.io;

  IoNodeStateImpl _state;
  IoNodeStateBuilder? _builder;

  // For convenience
  @override
  ItemIo? get requirements => null;
  @override
  ProductionLine get productionLine => this;
  @override
  NodeGeometryImpl get nodeGeometry => state.nodeGeometry;
  @override
  Set<Edge> get parents => state.parents;
  @override
  Set<Edge> get children => state.children;
  @override
  Map<InGameItem, List<Edge>> get inputEdges => state.inputEdges;
  @override
  Map<InGameItem, List<Edge>> get outputEdges => state.outputEdges;
  @override
  ProductionLineIo? get io => state.io;

  IoNode.addToBasePlanner({
    required BasePlanner basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required this.ioItem,
  }) : _basePlanner = basePlanner,
       _state = IoNodeStateImpl._(name: 'TODO'),
       inputItems = Set.unmodifiable([ioItem]),
       ioRatios = ItemIo(inputs: {ioItem: 1.0}, outputs: {ioItem: 1.0});

  @override
  IoNodeState get state => _builder ?? _state;
  @override
  set state(IoNodeStateImpl state) {
    _basePlanner.throwIfMutationNotPermitted();

    _state = state;
  }

  @override
  void remove() => throw UnimplementedError();

  @override
  IoNodeStateBuilder getStateBuilder() => throw UnimplementedError();

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => _basePlanner.selectedElements.contains(this);

  @override
  void select() => _basePlanner.selectElement(this);

  @override
  void deselect() => _basePlanner.deselectElement(this);

  @override
  NodeElement<dynamic, NodeEvent> getInputItemNode(InGameItem item) {
    if (ioItem == item) {
      return this;
    } else {
      throw NodeException('Node $this cannot produce / consume item $item');
    }
  }

  @override
  NodeElement<dynamic, NodeEvent> getOutputItemNode(InGameItem item) =>
      getInputItemNode(item);

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometryImpl nodeGeometry) =>
      notifyListeners(NodeEvent.geometryOp(nodeGeometry));

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  IoNodeIo calculate(ItemIo constraints) {
    // TODO: implement calculate
    throw UnimplementedError();
  }

  @override
  void notifyListenersOfStateUpdate(
    IoNodeStateImpl oldState,
    IoNodeStateImpl newState,
  ) {
    // TODO: implement notifyListenersOfStateUpdate
    throw UnimplementedError();
  }
}

abstract class IoNodeState {
  IoNodeIo? get io;
  String get name;

  NodeGeometryImpl get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;

  Map<InGameItem, List<Edge>> get outputEdges;
  Map<InGameItem, List<Edge>> get inputEdges;
}

class IoNodeStateImpl implements IoNodeState, ToJson {
  @override
  final IoNodeIo? io;
  @override
  final String name;

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

  IoNodeStateImpl._({
    this.io,
    required this.name,
    this.nodeGeometry = NodeGeometryImpl.uninitialised,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
  }) : parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class IoNodeStateBuilder
    implements NodeStateBuilder<IoNodeStateImpl>, IoNodeState {
  @override
  void addChild(Edge chidEdge) {
    // TODO: implement addChild
    throw UnimplementedError();
  }

  @override
  void addParent(Edge parentEdge) {
    // TODO: implement addParent
    throw UnimplementedError();
  }

  @override
  IoNodeStateImpl build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  void removeChild(Edge childEdge) {
    // TODO: implement removeChild
    throw UnimplementedError();
  }

  @override
  void removeParent(Edge parentEdge) {
    // TODO: implement removeParent
    throw UnimplementedError();
  }

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) {
    // TODO: implement updateGeometry
    throw UnimplementedError();
  }

  @override
  // TODO: implement children
  Set<Edge> get children => throw UnimplementedError();

  @override
  // TODO: implement inputEdges
  Map<InGameItem, List<Edge>> get inputEdges => throw UnimplementedError();

  @override
  // TODO: implement io
  IoNodeIo? get io => throw UnimplementedError();

  @override
  // TODO: implement nodeGeometry
  NodeGeometryImpl get nodeGeometry => throw UnimplementedError();

  @override
  // TODO: implement outputEdges
  Map<InGameItem, List<Edge>> get outputEdges => throw UnimplementedError();

  @override
  // TODO: implement parents
  Set<Edge> get parents => throw UnimplementedError();

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();
}

class IoNodeIo extends ProductionLineIo {
  IoNodeIo({
    required super.constraints,
    required super.io,
    required super.totalProductionAndConsumption,
    required super.electricPowerConsumption,
    super.displayData = const [],
    required super.emissions,
  });
}
