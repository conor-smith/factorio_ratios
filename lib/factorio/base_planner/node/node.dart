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

  ProductionLineType get productionLineType;
  ProductionLineIoData get ioData;

  /// Must be set on [NodeType.consumer] and [NodeType.producer] nodes.
  /// Otherwise null.
  ItemIo? get internalConstraints;

  /// TODO - Document
  ItemIo get edgeConstraints;

  /// Total IO for this node
  ItemIo get itemIo;

  /// Io Ratios for this node
  ItemIo get ioRatios;

  @override
  NodeGeometryImpl get geometry;

  Map<InGameItem, Set<Edge>> get parents;
  Map<InGameItem, Set<Edge>> get children;

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

    // for (var parent in parents) {
    //   switch (parent.edgeType) {
    //     case EdgeType.requestItems:
    //       builder.addToOutputs(parent.item, parent.requestedAmount);

    //     case EdgeType.weakRequestItems:
    //       if (nodeType.honoursWeakRequests) {
    //         builder.addToOutputs(parent.item, parent.requestedAmount);
    //       }

    //     case EdgeType.pushExcess:
    //     case EdgeType.weakPushExcess:
    //       break;
    //   }
    // }

    // for (var child in children) {
    //   switch (child.edgeType) {
    //     case EdgeType.pushExcess:
    //       builder.addToInputs(child.item, child.requestedAmount);

    //     case EdgeType.weakPushExcess:
    //       if (nodeType.honoursWeakRequests) {
    //         builder.addToInputs(child.item, child.requestedAmount);
    //       }

    //     case EdgeType.requestItems:
    //     case EdgeType.weakRequestItems:
    //       break;
    //   }
    // }

    return builder.build();
  }
}

enum NodeType implements Comparable<NodeType> {
  /// If a [Graph] has multiple nodes that produce the same output, a combiner node
  /// can be used to conveniently combine all into one.
  combiner(
    isIo: false,
    hasInternalConstraints: false,
    outputPriority: 1,
    permittedParents: {...EdgeType.values},
    permittedChildren: {...EdgeType.values},
  ),

  /// Represents a resource available on the surface (eg. ore, crop, etc).
  resource(
    isIo: false,
    hasInternalConstraints: false,
    outputPriority: 2,
    permittedParents: {EdgeType.requestItems},
    permittedChildren: {EdgeType.requestItems, EdgeType.requestExcess},
  ),

  /// Node can connect to and accept inputs from nodes in [NodeElement.parentGraph].
  /// Child edges must belong to parentGraph of parentGraph
  input(
    isIo: true,
    hasInternalConstraints: false,
    outputPriority: 3,
    permittedParents: {...EdgeType.values},
    permittedChildren: {...EdgeType.values},
  ),

  /// Represents a player made production line.
  productionLine(
    isIo: false,
    hasInternalConstraints: false,
    outputPriority: 4,
    permittedParents: {...EdgeType.values},
    permittedChildren: {...EdgeType.values},
  ),

  /// Represents a node that only produces items. Children are not permitted.
  ///
  /// This node and [consumer] nodes MUST set [NodeElement.internalConstraints].
  /// This acts as a "root" node for the graph. No edge constraints can be set.
  producer(
    isIo: false,
    hasInternalConstraints: true,
    outputPriority: 100,
    permittedParents: {EdgeType.pushExcess, EdgeType.requestExcess},
    permittedChildren: {},
  ),

  /// Represents a node capable of disposing of excess items (eg. space, lava lake).
  disposal(
    isIo: false,
    hasInternalConstraints: false,
    outputPriority: 100,
    permittedParents: {EdgeType.pushExcess, EdgeType.requestExcess},
    permittedChildren: {
      EdgeType.pushExcess,
      EdgeType.requestItems,
      EdgeType.requestExcess,
    },
  ),

  /// Node can connect and output to nodes in [NodeElement.parentGraph].
  /// Parent edges must belong to parentGraph of parentGraph.
  output(
    isIo: true,
    hasInternalConstraints: false,
    outputPriority: 100,
    permittedParents: {...EdgeType.values},
    permittedChildren: {...EdgeType.values},
  ),

  /// Represents a root node in the graph that consumes items. Parents are not permitted.
  ///
  /// This node and [producer] nodes MUST set [NodeElement.internalConstraints].
  /// This acts as a "root" node for the graph. No edge constraints can be set.
  consumer(
    isIo: false,
    hasInternalConstraints: true,
    outputPriority: 100,
    permittedParents: {},
    permittedChildren: {EdgeType.requestItems, EdgeType.requestExcess},
  );

  final bool isIo;
  final bool hasInternalConstraints;
  final int outputPriority;
  final Set<EdgeType> permittedParents;
  final Set<EdgeType> permittedChildren;

  const NodeType({
    required this.isIo,
    required this.hasInternalConstraints,
    required this.outputPriority,
    required this.permittedParents,
    required this.permittedChildren,
  });

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
