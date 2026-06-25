import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

part 'abstract_node_state.dart';

abstract interface class NodeElement<St extends NodeState, E extends NodeEvent>
    implements BasePlannerElement<St, E> {
  NodeType get nodeType;

  ProductionLine get productionLine;
  ProductionLineIo get io;

  ItemIo? get requirements;

  @override
  NodeGeometryImpl get geometry;

  @override
  NodeStateBuilder<St> getStateBuilder();

  Set<Edge> get parents;
  Set<Edge> get children;

  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;

  NodeElement getOutputItemNode(InGameItem item);
  NodeElement getInputItemNode(InGameItem item);
}

abstract interface class NodeState {
  Set<Edge> get parents;
  Set<Edge> get children;
  ProductionLineIo get io;
  NodeGeometryImpl get geometry;
}

enum NodeType implements Comparable<NodeType> {
  /// Node can connect to and accept inputs from nodes in [NodeElement.parentGraph].
  /// All [EdgeType]s are permitted so long as edges connecting to external nodes are inputs.
  input(outputPriority: 1, isIo: true),

  /// If a [Graph] has multiple nodes that produce the same output, a combiner node
  /// can be used to combine all those outputs into one. Exists primarily for convenience
  combiner(outputPriority: 2),

  /// Represents a leaf node in the a [Graph] that outputs items.
  /// This node is not allowed to have children.
  resource(outputPriority: 3),

  /// Represents a production line.
  productionLine(outputPriority: 4),

  /// Represents a leaf node in the a [Graph] that consumes items.
  /// This node is not allowed to have children.
  disposal(),

  /// Node can connect to and output to nodes in [NodeElement.parentGraph].
  /// All [EdgeType]s are permitted so long as edges connecting to external nodes are outputs.
  output(isIo: true),

  /// Represents a root node in the graph that consumes items. Parents are not permitted.
  ///
  /// Only these nodes and [producer] nodes are permitted to set [NodeElement.requirements].
  consumer(),

  /// Represents a root node in the graph that produces items. Parents are not permitted.
  ///
  /// Only these nodes and [consumer] nodes are permitted to set [NodeElement.requirements].
  producer(outputPriority: 3);

  final bool isIo;
  final int outputPriority;

  const NodeType({this.isIo = false, this.outputPriority = 100});

  @override
  int compareTo(NodeType other) =>
      outputPriority.compareTo(other.outputPriority);
}

class NodeEvent {
  final NodeEventType nodeEventType;

  final NodeGeometry? geometry;

  NodeEvent.geometryOp(NodeGeometry this.geometry)
    : nodeEventType = NodeEventType.geometryOp;

  NodeEvent.stateUpdate()
    : nodeEventType = NodeEventType.stateUpdate,
      geometry = null;

  NodeEvent.other() : nodeEventType = NodeEventType.other, geometry = null;
}

enum NodeEventType {
  geometryOp(true),
  stateUpdate(true),
  other(false);

  final bool updateRequired;

  const NodeEventType(this.updateRequired);
}

class NodeException extends BasePlannerException {
  const NodeException(super.message, [super.cause]);
}
