import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/change_tracker/change_trackers.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/utility/json.dart';

part 'production_line_node.dart';
part 'production_line_node_state.dart';

abstract class NodeElement<St extends NodeState, E extends NodeEvent>
    extends BasePlannerElement<St, E> {
  NodeElement(super.basePlanner);

  NodeType get nodeType;

  ProductionLineType get productionLineType;
  ProductionLineIoData get ioData;

  /// Must be set on [NodeType.consumer] and [NodeType.producer] nodes.
  /// Otherwise null.
  ItemIo? get internalConstraints;

  /// TODO - Document
  ItemIo get edgeConstraints;

  /// Io Ratios for this node
  ItemIo get ioRatios;

  // TODO - Document
  ItemIo get unusedIo;

  @override
  NodeGeometryImpl get geometry;
  @override
  NodeChangeTracker getChangeTracker();
  @override
  NodeStateBuilder<St> getStateBuilder();

  Map<InGameItem, Set<Edge>> get parents;
  Map<InGameItem, Set<Edge>> get children;

  Iterable<Edge> get allParents;
  Iterable<Edge> get allChildren;

  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;

  ProdLineNode getOutputItemNode(InGameItem item);
  ProdLineNode getInputItemNode(InGameItem item);

  GeometryOperation beginDrag() => GeometryOperation.drag(
    basePlanner,
    parentGraph,
    parentGraph.selectedElements.whereType<NodeElement>(),
  );
}

abstract mixin class NodeState {
  ProductionLineIoData get ioData;
  ItemIoImpl get edgeConstraints;
  ItemIoImpl get ioRatios;
  ItemIoImpl get unusedIo;

  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;

  Map<InGameItem, Set<Edge>> get parents;
  Map<InGameItem, Set<Edge>> get children;
  NodeGeometryImpl get geometry;

  Set<Edge> get allParents =>
      parents.values.expand((edgeSet) => edgeSet).toSet();
  Set<Edge> get allChildren =>
      children.values.expand((edgeSet) => edgeSet).toSet();
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

  const NodeEvent.update()
    : nodeEventType = NodeEventType.update,
      geometry = null;

  NodeEvent.other() : nodeEventType = NodeEventType.other, geometry = null;
}

enum NodeEventType {
  geometryOp(true),
  stateUpdate(true),
  update(true),
  other(false);

  final bool updateRequired;

  const NodeEventType(this.updateRequired);
}

class NodeException extends BasePlannerException {
  const NodeException(super.message, [super.cause]);
}
