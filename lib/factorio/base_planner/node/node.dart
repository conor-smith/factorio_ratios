import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

abstract interface class NodeElement<St, E extends NodeEvent>
    implements BasePlannerElement<St, E> {
  NodeType get nodeType;

  ProductionLine get productionLine;
  ProductionLineIo? get io;

  ItemIo? get requirements;

  NodeGeometryImpl get nodeGeometry;

  @override
  NodeStateBuilder<St> getStateBuilder();

  Set<Edge> get parents;
  Set<Edge> get children;

  Map<InGameItem, List<Edge>> get outputEdges;
  Map<InGameItem, List<Edge>> get inputEdges;

  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;

  static Map<InGameItem, List<Edge>> calculateOutputEdges(
    Set<Edge> parents,
    Set<Edge> children,
  ) {
    Map<InGameItem, List<Edge>> outputEdges = {};

    for (var edge in parents) {
      if (edge.edgeType == EdgeType.requestItems) {
        outputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }
    for (var edge in children) {
      if (edge.edgeType == EdgeType.acceptExcess) {
        outputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }

    outputEdges.updateAll((item, edges) => List.unmodifiable(edges));
    return Map.unmodifiable(outputEdges);
  }

  static Map<InGameItem, List<Edge>> calculateInputEdges(
    Set<Edge> parents,
    Set<Edge> children,
  ) {
    Map<InGameItem, List<Edge>> inputEdges = {};

    for (var edge in parents) {
      if (edge.edgeType == EdgeType.acceptExcess) {
        inputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }
    for (var edge in children) {
      if (edge.edgeType == EdgeType.requestItems) {
        inputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }

    inputEdges.updateAll((item, edges) => List.unmodifiable(edges));
    return Map.unmodifiable(inputEdges);
  }
}

abstract interface class NodeStateBuilder<T> implements Builder<T> {
  void updateGeometry(NodeGeometryImpl nodeGeometry);
  void addParent(Edge parentEdge);
  void removeParent(Edge parentEdge);
  void addChild(Edge chidEdge);
  void removeChild(Edge childEdge);
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
  resource(outputPriority: 3, childrenPermitted: false),

  /// Represents a production line.
  productionLine(outputPriority: 4),

  /// Represents a leaf node in the a [Graph] that consumes items.
  /// This node is not allowed to have children.
  disposal(childrenPermitted: false),

  /// Node can connect to and output to nodes in [NodeElement.parentGraph].
  /// All [EdgeType]s are permitted so long as edges connecting to external nodes are outputs.
  output(isIo: true),

  /// Represents a root node in the graph that consumes items. Parents are not permitted.
  ///
  /// Only these nodes and [producer] nodes are permitted to set [NodeElement.requirements].
  consumer(parentsPermitted: false),

  /// Represents a root node in the graph that produces items. Parents are not permitted.
  ///
  /// Only these nodes and [consumer] nodes are permitted to set [NodeElement.requirements].
  producer(parentsPermitted: false, outputPriority: 3);

  final bool isIo;
  final bool parentsPermitted;
  final bool childrenPermitted;
  final int outputPriority;

  const NodeType({
    this.isIo = false,
    this.parentsPermitted = true,
    this.childrenPermitted = false,
    this.outputPriority = 100,
  });

  @override
  int compareTo(NodeType other) =>
      outputPriority.compareTo(other.outputPriority);
}

class NodeEvent {
  final NodeEventType nodeEventType;

  final NodeGeometry? nodeGeometry;

  NodeEvent.geometryOp(NodeGeometry this.nodeGeometry)
    : nodeEventType = NodeEventType.geometryOp;

  NodeEvent.stateUpdate()
    : nodeEventType = NodeEventType.stateUpdate,
      nodeGeometry = null;

  NodeEvent.other() : nodeEventType = NodeEventType.other, nodeGeometry = null;
}

enum NodeEventType {
  geometryOp(true),
  stateUpdate(true),
  other(false);

  final bool updateRequired;

  const NodeEventType(this.updateRequired);
}
