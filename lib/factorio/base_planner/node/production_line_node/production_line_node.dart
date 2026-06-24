import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'production_line_node_state.dart';

class ProdLineNode
    with EventNotifier<NodeEvent>
    implements NodeElement<ProdLineNodeState, NodeEvent> {
  @override
  final BasePlanner basePlanner;

  @override
  final Graph parentGraph;
  @override
  final NodeType nodeType;

  // For convenience
  @override
  ItemIo? get requirements => state.requirements;
  @override
  ProductionLine get productionLine => _state.productionLine;
  @override
  NodeGeometryImpl get nodeGeometry => state.nodeGeometry;
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

  ProdLineNodeStateImpl _state;
  ProdLineNodeStateBuilder? _builder;

  ProdLineNode.addToBasePlanner({
    required this.basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
    NodeGeometryImpl nodeGeometry = NodeGeometryImpl.uninitialised,
    ProductionLineIo? io,
  }) : _state = ProdLineNodeStateImpl._initial(
         productionLine: productionLine,
         nodeGeometry: nodeGeometry,
         io: io,
       ) {
    if (nodeType.isIo) {
      throw NodeException(
        'ProdLineNode is not permitted to be of nodeType $nodeType',
      );
    }

    _builder = ProdLineNodeStateBuilder.from(this, _state);
    _builder!.addSelf();
  }

  @override
  ProdLineNodeState get state => _builder ?? _state;
  @override
  set state(ProdLineNodeStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();

    // Validate state, update listeners
    _state = state;
  }

  @override
  ProdLineNodeStateBuilder getStateBuilder() {
    _builder ??= ProdLineNodeStateBuilder.from(this, _state);

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
  NodeElement getOutputItemNode(InGameItem item) {
    if (outputItems.contains(item)) {
      return this;
    } else {
      throw NodeException('Node $this cannot produce $item');
    }
  }

  @override
  NodeElement getInputItemNode(InGameItem item) {
    if (inputItems.contains(item)) {
      return this;
    } else {
      throw NodeException('Node $this cannot consume $item');
    }
  }

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometryImpl nodeGeometry) =>
      notifyListeners(NodeEvent.geometryOp(nodeGeometry));

  @override
  void notifyListenersOfStateUpdate(
    ProdLineNodeStateImpl oldState,
    ProdLineNodeStateImpl newState,
  ) {
    // TODO: implement notifyListenersOfStateUpdate
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
