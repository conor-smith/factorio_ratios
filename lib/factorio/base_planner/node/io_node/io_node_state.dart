part of 'io_node.dart';

abstract class IoNodeState {
  IoNodeIo? get io;

  NodeGeometryImpl get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;
}

class IoNodeStateImpl extends AbstractNodeState implements IoNodeState, ToJson {
  @override
  final IoNodeIo? io;

  IoNodeStateImpl._initial({required this.io, required super.nodeGeometry})
    : super.initial();

  IoNodeStateImpl._(
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

class IoNodeStateBuilder extends AbstractNodeStateBuilder<IoNodeStateImpl>
    implements IoNodeState {
  @override
  final IoNode node;

  IoNodeIo? _io;

  @override
  IoNodeIo? get io => _io;

  IoNodeStateBuilder._from(this.node) : _io = node.io, super.from(node);

  @override
  void addSelf() {
    node.parentGraph.getStateBuilder().addIoNode(node);
  }

  @override
  void removeSelf() {
    super.removeSelf();

    node.parentGraph.getStateBuilder().removeIoNode(node);
  }

  @override
  ProductionLine<ProductionLineIo> get productionLine => node;

  @override
  void calculateIo(ItemIo constraints) {
    _io = node.calculate(constraints);
    clearParentIo();
  }

  @override
  void clearIo() {
    _io = null;
    clearParentIo();
  }

  @override
  IoNodeStateImpl build() => IoNodeStateImpl._(
    node,
    io: io,
    nodeGeometry: nodeGeometry,
    parents: parents,
    children: children,
  );
}
