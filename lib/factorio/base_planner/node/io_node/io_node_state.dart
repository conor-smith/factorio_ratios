part of 'io_node.dart';

abstract class IoNodeState implements NodeState {
  @override
  IoNodeIo? get io;
}

class IoNodeStateImpl extends AbstractNodeState implements IoNodeState, ToJson {
  @override
  final IoNodeIo? io;

  IoNodeStateImpl._initial({required this.io, required super.nodeGeometry})
    : super.initial();

  IoNodeStateImpl(
    IoNode node, {
    required this.io,
    required super.nodeGeometry,
    required super.parents,
    required super.children,
  }) : super(node, productionLine: node) {
    Set<Edge> internalEdges, externalEdges;

    if (node.nodeType == NodeType.output) {
      internalEdges = children;
      externalEdges = parents;
    } else {
      internalEdges = parents;
      externalEdges = children;
    }

    for (var edge in internalEdges) {
      if (edge.parentGraph != node.parentGraph) {
        throw NodeException(
          'Edge $edge connected to node $this belongs to graph ${edge.parentGraph}',
        );
      }
    }

    for (var edge in externalEdges) {
      if (edge.parentGraph != node.parentGraph.parentGraph) {
        throw NodeException(
          'Edge $edge connected to node $this must be part of parent graph ${node.parentGraph.parentGraph} to allow for IO',
        );
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
