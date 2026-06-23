import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'io_node_state.dart';

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
  Set<Edge> get externalParents => throw UnimplementedError();
  Set<Edge> get externalChildren => throw UnimplementedError();
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
