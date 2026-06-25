import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'io_node_state.dart';

class IoNode
    with EventNotifier<NodeEvent>, ProductionLine<IoNodeIo>
    implements NodeElement<IoNodeState, NodeEvent> {
  @override
  final BasePlanner basePlanner;

  @override
  final Graph parentGraph;
  @override
  final NodeType nodeType;
  @override
  final String name;

  final InGameItem ioItem;

  @override
  Set<InGameItem> get inputItems => _ioItems;
  @override
  Set<InGameItem> get outputItems => _ioItems;

  @override
  Icon? get icon => ioItem.icon;
  @override
  final ItemIo? ioRatios;
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
  NodeGeometryImpl get geometry => state.geometry;
  @override
  Set<Edge> get parents => state.parents;
  @override
  Set<Edge> get children => state.children;
  @override
  IoNodeIo get io => state.io;

  final Set<InGameItem> _ioItems;

  IoNode.addToBasePlanner({
    required this.basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required this.ioItem,
    NodeGeometryImpl geometry = NodeGeometryImpl.uninitialised,
    IoNodeIo io = const IoNodeIo.empty(),
  }) : _state = IoNodeStateImpl._initial(geometry: geometry, io: io),
       _ioItems = Set.unmodifiable([ioItem]),
       name = '$ioItem $nodeType',
       ioRatios = ItemIo(inputs: {ioItem: 1.0}, outputs: {ioItem: 1.0}) {
    if (!nodeType.isIo) {
      throw NodeException('IO node cannot have node type $nodeType');
    }

    _builder = IoNodeStateBuilder.from(this, _state);
    _builder!.addSelf();
  }

  @override
  IoNodeState get state => _builder ?? _state;
  @override
  set state(IoNodeStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();
    _builder = null;
    _state = state;
  }

  @override
  IoNodeStateBuilder getStateBuilder() {
    _builder ??= IoNodeStateBuilder.from(this, _state);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => basePlanner.selectedElements.contains(this);

  @override
  void select() => basePlanner.selectElement(this);

  @override
  void deselect() => basePlanner.deselectElement(this);

  @override
  IoNode getInputItemNode(InGameItem item) => _getIoNode(item);

  @override
  IoNode getOutputItemNode(InGameItem item) => _getIoNode(item);

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometryImpl geometry) =>
      notifyListeners(NodeEvent.geometryOp(geometry));

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  IoNodeIo calculate([ItemIo constraints = ItemIo.empty]) {
    // TODO: implement calculate
    throw UnimplementedError();
  }

  @override
  void notifyListenersOfStateUpdate(
    IoNodeStateImpl oldState,
    IoNodeStateImpl newState,
  ) {
    if (oldState.geometry != newState.geometry) {
      notifyListeners(NodeEvent.geometryOp(newState.geometry));
    }
  }

  IoNode _getIoNode(InGameItem item) {
    if (ioItem == item) {
      return this;
    } else {
      throw NodeException('Node $this cannot produce / consume item $item');
    }
  }
}

class IoNodeIo extends ProductionLineIo {
  IoNodeIo({required super.constraints})
    : super(totalProductionAndConsumption: ItemIo.empty);

  const IoNodeIo.empty() : super.empty();
}
