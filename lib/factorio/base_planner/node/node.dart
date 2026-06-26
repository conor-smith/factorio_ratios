import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'production_line_node.dart';
part 'production_line_node_state.dart';

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

  ProdLineNode getOutputItemNode(InGameItem item);
  ProdLineNode getInputItemNode(InGameItem item);
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
  input(true, false, 1),

  /// If a [Graph] has multiple nodes that produce the same output, a combiner node
  /// can be used to combine all those outputs into one. Exists primarily for convenience
  combiner(false, false, 2),

  /// Represents a leaf node in the a [Graph] that outputs items.
  /// This node is not allowed to have children.
  resource(false, false, 3),

  /// Represents a production line.
  productionLine(false, false, 4),

  /// Represents a root node in the graph that produces items. Parents are not permitted.
  ///
  /// Only these nodes and [consumer] nodes are permitted to set [NodeElement.requirements].
  producer(false, true, 5),

  /// Represents a leaf node in the a [Graph] that consumes items.
  /// This node is not allowed to have children.
  disposal(false, false, 100),

  /// Node can connect to and output to nodes in [NodeElement.parentGraph].
  /// All [EdgeType]s are permitted so long as edges connecting to external nodes are outputs.
  output(true, false, 100),

  /// Represents a root node in the graph that consumes items. Parents are not permitted.
  ///
  /// Only these nodes and [producer] nodes are permitted to set [NodeElement.requirements].
  consumer(false, true, 100);

  final bool isIo;
  final bool isRoot;
  final int outputPriority;

  const NodeType(this.isIo, this.isRoot, this.outputPriority);

  @override
  int compareTo(NodeType other) =>
      outputPriority.compareTo(other.outputPriority);

  void throwIfInvalid(ProductionLine prodLine) {
    switch (this) {
      case NodeType.combiner:
        if (prodLine is! CombinerLine) {
          throw const NodeException(
            'Combiner node must use Combiner production line',
          );
        }

      case NodeType.output:
      case NodeType.input:
        if (prodLine is! IoLine) {
          throw const NodeException('IO node must use IO production line');
        }

      case NodeType.consumer:
        if (prodLine.inputItems.isEmpty || prodLine.outputItems.isNotEmpty) {
          throw const NodeException(
            'Consumer node must have inputs and no outputs',
          );
        }
        continue ensureValidProdLineType;

      case NodeType.producer:
        if (prodLine.outputItems.isEmpty || prodLine.inputItems.isNotEmpty) {
          throw const NodeException(
            'Producer node must have outputs and no inputs',
          );
        }
        continue ensureValidProdLineType;

      ensureValidProdLineType:
      default:
        if (prodLine is IoLine || prodLine is CombinerLine) {
          throw NodeException(
            'Node of type $NodeType cannot have production line of type ${prodLine.runtimeType}',
          );
        }
    }
  }
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
