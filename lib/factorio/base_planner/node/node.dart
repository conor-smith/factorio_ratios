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
  /// Child edges must belong to parentGraph of parentGraph
  input(true, false, 1),

  /// If a [Graph] has multiple nodes that produce the same output, a combiner node
  /// can be used to combine all those outputs into one.
  combiner(false, false, 2),

  /// Represents a resource available on the surface (eg. ore, crop, etc).
  ///
  /// Parents of type [EdgeType.pushExcess] are not permitted.
  /// Children of type [EdgeType.pushExcess] are permitted, but the node
  /// will only consume as much as is required to fulfil requests from parents
  /// of type [EdgeType.requestItems].
  resource(false, false, 3),

  /// Represents a player made production line.
  productionLine(false, false, 4),

  /// Represents a root node in the graph that produces items. Children are not permitted.
  ///
  /// Only these nodes and [consumer] nodes are permitted to set [NodeElement.requirements].
  /// All edge types are permitted in both [NodeElement.parents] and [NodeElement.children],
  /// and each indivual item requirement will be set to the highest value between
  /// [NodeElement.requirements] and out of all constraints set by edges.
  producer(false, true, 5),

  /// Represents a leaf node in the a [Graph] that consumes items.
  ///
  /// Children of type [EdgeType.requestItems] are not permitted.
  /// Parents of type [EdgeType.requestItems] are permitted, but the node will
  /// only request as much as is required to fulfil requests from children
  /// of type [EdgeType.pushExcess].
  disposal(false, false, 100),

  /// Node can connect to and output to nodes in [NodeElement.parentGraph].
  /// Parent edges must belong to parentGraph of parentGraph.
  output(true, false, 100),

  /// Represents a root node in the graph that consumes items. Parents are not permitted.
  ///
  /// Only these nodes and [producer] nodes are permitted to set [NodeElement.requirements].
  /// All edge types are permitted in both [NodeElement.parents] and [NodeElement.children],
  /// and each indivual item requirement will be set to the highest value between
  /// [NodeElement.requirements] and out of all constraints set by edges.
  consumer(false, true, 100);

  final bool isIo;
  final bool isRoot;
  final int outputPriority;

  const NodeType(this.isIo, this.isRoot, this.outputPriority);

  @override
  int compareTo(NodeType other) =>
      outputPriority.compareTo(other.outputPriority);

  void verify(
    ProductionLine prodLine,
    ItemIo? requirements,
    Graph parentGraph,
    Set<Edge> parents,
    Set<Edge> children,
  ) {
    switch (this) {
      case NodeType.input:
        if (children.any(
          (child) => child.parentGraph != parentGraph.parentGraph,
        )) {
          throw const NodeException(
            'All child edges of input node must belong to parentGraph of parentGraph',
          );
        }
        _verifyIoProdLine(prodLine);
        _verifyNoRequirements(requirements);

      case NodeType.output:
        if (parents.any(
          (parent) => parent.parentGraph != parentGraph.parentGraph,
        )) {
          throw const NodeException(
            'All parent edges of output node must belong to parentGraph of parentGraph',
          );
        }
        _verifyIoProdLine(prodLine);
        _verifyNoRequirements(requirements);

      case NodeType.consumer:
        if (prodLine.inputItems.isEmpty || prodLine.outputItems.isNotEmpty) {
          throw const NodeException(
            'Consumer node must have inputs and no outputs',
          );
        }
        _verifyOrdinaryLine(prodLine);
        _verifyRequirements(requirements);

      case NodeType.producer:
        if (prodLine.outputItems.isEmpty || prodLine.inputItems.isNotEmpty) {
          throw const NodeException(
            'Producer node must have outputs and no inputs',
          );
        }
        _verifyOrdinaryLine(prodLine);
        _verifyRequirements(requirements);

      case NodeType.combiner:
        if (prodLine is! CombinerLine) {
          throw const NodeException(
            'Combiner node must use Combiner production line',
          );
        }
        _verifyNoRequirements(requirements);

      case NodeType.resource:
        if (children.any((child) => child.edgeType == EdgeType.pushExcess)) {
          throw const NodeException(
            'Resource node may not have pushExcess children',
          );
        }
        _verifyOrdinaryLine(prodLine);
        _verifyNoRequirements(requirements);

      case NodeType.disposal:
        if (parents.any((child) => child.edgeType == EdgeType.requestItems)) {
          throw const NodeException(
            'Disposal node may not have requestItems children',
          );
        }
        _verifyOrdinaryLine(prodLine);
        _verifyNoRequirements(requirements);

      case NodeType.productionLine:
        _verifyOrdinaryLine(prodLine);
        _verifyNoRequirements(requirements);
    }
  }

  void _verifyIoProdLine(ProductionLine productionLine) {
    if (productionLine is! IoLine) {
      throw const NodeException('IO node must use IO production line');
    }
  }

  void _verifyOrdinaryLine(ProductionLine productionLine) {
    if (productionLine is IoLine || productionLine is CombinerLine) {
      throw NodeException(
        'Node of type $this is not permitted to have production line of type ${productionLine.runtimeType}',
      );
    }
  }

  void _verifyNoRequirements(ItemIo? requirements) {
    if (requirements != null) {
      throw NodeException(
        'Node of type $this is not permitted to have requirements',
      );
    }
  }

  void _verifyRequirements(ItemIo? requirements) {
    if (requirements == null) {
      throw NodeException('Node of type $this must have requirements');
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
