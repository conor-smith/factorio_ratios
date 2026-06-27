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

abstract interface class NodeElement<St, E extends NodeEvent>
    implements BasePlannerElement<St, E> {
  NodeType get nodeType;

  ProductionLine get productionLine;
  ProductionLineIoData get ioData;

  /// Must be set on [NodeType.consumer] and [NodeType.producer] nodes.
  /// Otherwise null.
  ItemIo? get internalConstraints;

  /// The constraints set by parent edges of type [EdgeType.requestItems] and
  /// [EdgeType.weakRequestItems], and by child edges of type
  /// [EdgeType.pushExcess] and [EdgeType.weakPushExcess]
  ItemIo get edgeConstraints;

  /// Total IO for this node
  ItemIo get itemIo;

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

  static ItemIoImpl calculateEdgeConstraints(
    NodeType nodeType,
    Iterable<Edge> parents,
    Iterable<Edge> children,
  ) {
    var builder = ItemIoBuilder();

    for (var parent in parents) {
      switch (parent.edgeType) {
        case EdgeType.requestItems:
          builder.addToOutputs(parent.item, parent.requestedAmount);

        case EdgeType.weakRequestItems:
          if (nodeType.honoursWeakRequests) {
            builder.addToOutputs(parent.item, parent.requestedAmount);
          }

        case EdgeType.pushExcess:
        case EdgeType.weakPushExcess:
          break;
      }
    }

    for (var child in children) {
      switch (child.edgeType) {
        case EdgeType.pushExcess:
          builder.addToInputs(child.item, child.requestedAmount);

        case EdgeType.weakPushExcess:
          if (nodeType.honoursWeakRequests) {
            builder.addToInputs(child.item, child.requestedAmount);
          }

        case EdgeType.requestItems:
        case EdgeType.weakRequestItems:
          break;
      }
    }

    return builder.build();
  }
}

enum NodeType implements Comparable<NodeType> {
  /// If a [Graph] has multiple nodes that produce the same output, a combiner node
  /// can be used to conveniently combine all into one.
  combiner(
    isIo: false,
    hasInternalConstraints: false,
    honoursWeakRequests: true,
    outputPriority: 1,
  ),

  /// Represents a resource available on the surface (eg. ore, crop, etc).
  ///
  /// In the event this node does consume items,
  /// children may be of any type except [EdgeType.pushExcess].
  /// The node will only consume as much as is required to fulfil parent requests,
  /// so an edge of type [EdgeType.weakPushExcess] may not
  /// be able to push all it's items.
  resource(
    isIo: false,
    hasInternalConstraints: false,
    honoursWeakRequests: false,
    outputPriority: 2,
  ),

  /// Node can connect to and accept inputs from nodes in [NodeElement.parentGraph].
  /// Child edges must belong to parentGraph of parentGraph
  input(
    isIo: true,
    hasInternalConstraints: false,
    honoursWeakRequests: true,
    outputPriority: 3,
  ),

  /// Represents a player made production line.
  productionLine(
    isIo: false,
    hasInternalConstraints: false,
    honoursWeakRequests: true,
    outputPriority: 4,
  ),

  /// Represents a node that only produces items. Children are not permitted.
  ///
  /// This node and [consumer] nodes MUST set [NodeElement.internalConstraints].
  /// If parents of type [EdgeType.requestItems] exist, the final constraint for
  /// each item will be given by the larger of two values
  /// - The value at [NodeElement.internalConstraints]
  /// - The sum value of all parents of type [EdgeType.requestItems]
  producer(
    isIo: false,
    hasInternalConstraints: true,
    honoursWeakRequests: true,
    outputPriority: 5,
  ),

  /// Represents a node capable of disposing of excess items (eg. space, lava lake).
  ///
  /// In the event this node does produce items,
  /// children may be of any type except [EdgeType.requestItems].
  /// The node will only produce as much as is required to fulfil child requests,
  /// so using [EdgeType.weakRequestItems] may not be able to request all needed items.
  disposal(
    isIo: false,
    hasInternalConstraints: false,
    honoursWeakRequests: false,
    outputPriority: 100,
  ),

  /// Node can connect to and output to nodes in [NodeElement.parentGraph].
  /// Parent edges must belong to parentGraph of parentGraph.
  output(
    isIo: true,
    hasInternalConstraints: false,
    honoursWeakRequests: true,
    outputPriority: 100,
  ),

  /// Represents a root node in the graph that consumes items. Parents are not permitted.
  ///
  /// This node and [producer] nodes MUST set [NodeElement.internalConstraints].
  /// If children of type [EdgeType.pushExcess] exist, the final constraint for
  /// each item will be given by the larger of two values
  /// - The value at [NodeElement.internalConstraints]
  /// - The sum value of all children of type [EdgeType.requestItems]
  consumer(
    isIo: false,
    hasInternalConstraints: true,
    honoursWeakRequests: true,
    outputPriority: 100,
  );

  final bool isIo;
  final bool hasInternalConstraints;
  final bool honoursWeakRequests;
  final int outputPriority;

  const NodeType({
    required this.isIo,
    required this.hasInternalConstraints,
    required this.honoursWeakRequests,
    required this.outputPriority,
  });

  @override
  int compareTo(NodeType other) =>
      outputPriority.compareTo(other.outputPriority);

  void verify(Graph parentGraph, ProdLineNodeStateImpl nodeState) {
    switch (this) {
      case NodeType.input:
        if (nodeState.children.any(
          (child) => child.parentGraph != parentGraph.parentGraph,
        )) {
          throw const NodeException(
            'All child edges of input node must belong to parentGraph of parentGraph',
          );
        }
        _verifyIoProdLine(nodeState);
        _verifyNoRequirements(nodeState);

      case NodeType.output:
        if (nodeState.parents.any(
          (parent) => parent.parentGraph != parentGraph.parentGraph,
        )) {
          throw const NodeException(
            'All parent edges of output node must belong to parentGraph of parentGraph',
          );
        }
        _verifyIoProdLine(nodeState);
        _verifyNoRequirements(nodeState);

      case NodeType.consumer:
        if (nodeState.productionLine.inputItems.isEmpty ||
            nodeState.productionLine.outputItems.isNotEmpty) {
          throw const NodeException(
            'Consumer node must have inputs and no outputs',
          );
        } else if (nodeState.children.isNotEmpty ||
            nodeState.parents.any((edge) => !edge.edgeType.constrainsParents)) {
          // TODO: Allow pushExcess edges once I have loops working
          throw const NodeException('Consumer node can only request items');
        }
        _verifyOrdinaryLine(nodeState);
        _verifyRequirements(nodeState);

      case NodeType.producer:
        if (nodeState.productionLine.outputItems.isEmpty ||
            nodeState.productionLine.inputItems.isNotEmpty) {
          throw const NodeException(
            'Producer node must have outputs and no inputs',
          );
        } else if (nodeState.parents.isNotEmpty ||
            nodeState.children.any((edge) => edge.edgeType.constrainsParents)) {
          // TODO: Allow request items edges once I have loops working
          throw const NodeException('Producer node can only push excess items');
        }
        _verifyOrdinaryLine(nodeState);
        _verifyRequirements(nodeState);

      case NodeType.combiner:
        if (nodeState.productionLine is! CombinerLine) {
          throw const NodeException(
            'Combiner node must use Combiner production line',
          );
        }
        _verifyNoRequirements(nodeState);

      case NodeType.resource:
        if (nodeState.children.any(
          (child) => child.edgeType == EdgeType.pushExcess,
        )) {
          throw const NodeException(
            'Resource node cannot had children of type pushExcess',
          );
        }
        _verifyOrdinaryLine(nodeState);
        _verifyNoRequirements(nodeState);

      case NodeType.disposal:
        if (nodeState.parents.any(
          (parent) => parent.edgeType == EdgeType.requestItems,
        )) {
          throw const NodeException(
            'Disposal node may not have parents of type requestItems',
          );
        }
        _verifyOrdinaryLine(nodeState);
        _verifyNoRequirements(nodeState);

      case NodeType.productionLine:
        _verifyOrdinaryLine(nodeState);
        _verifyNoRequirements(nodeState);
    }
  }

  void _verifyIoProdLine(ProdLineNodeState nodeState) {
    if (nodeState.productionLine is! IoLine) {
      throw const NodeException('IO node must use IO production line');
    }
  }

  void _verifyOrdinaryLine(ProdLineNodeState nodeState) {
    if (nodeState.productionLine is IoLine ||
        nodeState.productionLine is CombinerLine) {
      throw NodeException(
        'Node of type $this is not permitted to have production line of type ${productionLine.runtimeType}',
      );
    }
  }

  void _verifyNoRequirements(ProdLineNodeState nodeState) {
    if (nodeState.internalConstraints != null) {
      throw NodeException(
        'Node of type $this is not permitted to have internal constraints',
      );
    }
  }

  void _verifyRequirements(ProdLineNodeState nodeState) {
    if (nodeState.internalConstraints == null) {
      throw NodeException('Node of type $this must have internal constraints');
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
