import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'production_line_node_state.dart';

class ProdLineNode
    with EventNotifier<NodeEvent>
    implements NodeElement<ProdLineNodeState, NodeEvent> {
  final BasePlanner _basePlanner;

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
  Map<InGameItem, List<Edge>> get inputEdges => state.inputEdges;
  @override
  Map<InGameItem, List<Edge>> get outputEdges => state.outputEdges;
  @override
  ProductionLineIo? get io => state.io;
  @override
  Set<InGameItem> get inputItems => state.productionLine.inputItems;
  @override
  Set<InGameItem> get outputItems => state.productionLine.outputItems;

  ProdLineNodeStateImpl _state;
  ProdLineNodeStateBuilder? _builder;

  ProdLineNode.addToBasePlanner({
    required BasePlanner basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
    NodeGeometryImpl nodeGeometry = NodeGeometryImpl.uninitialised,
  }) : _basePlanner = basePlanner,
       _state = ProdLineNodeStateImpl._initial(productionLine: productionLine, nodeGeometry: nodeGeometry) {
    _builder = ProdLineNodeStateBuilder._from(this);
    _builder!.addSelf();
  }

  @override
  ProdLineNodeState get state => _builder ?? _state;
  @override
  set state(ProdLineNodeStateImpl state) {
    _basePlanner.throwIfMutationNotPermitted();

    // Validate state, update listeners
    _state = state;
  }

  @override
  ProdLineNodeStateBuilder getStateBuilder() {
    _builder ??= ProdLineNodeStateBuilder._from(this);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => _basePlanner.selectedElements.contains(this);

  @override
  void select() => _basePlanner.selectElement(this);

  @override
  void deselect() => _basePlanner.deselectElement(this);

  @override
  NodeElement getOutputItemNode(InGameItem item) {
    if (outputItems.contains(item)) {
      return this;
    } else {
      throw NodeException('Node $this cannot output $item');
    }
  }

  @override
  NodeElement getInputItemNode(InGameItem item) {
    if (inputItems.contains(item)) {
      return this;
    } else {
      throw NodeException('Node $this cannot accept $item as input');
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
