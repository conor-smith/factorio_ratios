part of 'io_node.dart';

abstract class IoNodeState {
  IoNodeIo? get io;

  NodeGeometryImpl get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;
}

class IoNodeStateImpl implements IoNodeState, ToJson {
  @override
  final IoNodeIo? io;

  @override
  final NodeGeometryImpl nodeGeometry;

  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  IoNodeStateImpl._initial({required this.io, required this.nodeGeometry})
    : parents = const {},
      children = const {};

  IoNodeStateImpl._(
    IoNode node, {
    required this.io,
    required this.nodeGeometry,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
  }) : parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children) {
    Set<Edge> internalEdges, externalEdges;

    for(var parent in this.parents) {
      if(parent.child != node) {
        throw NodeException('Edge $parent is not parent of node $node');
      }
    }
    for(var child in this.children) {
      if(child.parent != node) {
        throw NodeException('Edge $child is not child of node $node');
      }
    }

    if (node.nodeType == NodeType.output) {
      internalEdges = this.children;
      externalEdges = this.parents;
    } else {
      internalEdges = this.parents;
      externalEdges = this.children;
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

class IoNodeStateBuilder
    implements NodeStateBuilder<IoNodeStateImpl>, IoNodeState {
  final IoNode _node;

  IoNodeIo? _io;
  NodeGeometryImpl _nodeGeometry;
  Set<Edge> _parents;
  Set<Edge> _children;

  @override
  IoNodeIo? get io => _io;
  @override
  NodeGeometryImpl get nodeGeometry => _nodeGeometry;
  @override
  late final Set<Edge> parents = UnmodifiableSetView(_parents);
  @override
  late final Set<Edge> children = UnmodifiableSetView(_children);

  IoNodeStateBuilder._(this._node)
    : _io = _node.io,
      _nodeGeometry = _node.nodeGeometry,
      _parents = Set.from(_node.parents),
      _children = Set.from(_node.children);

  @override
  void addChild(Edge child) =>
    _children.add(child);

  @override
  void addParent(Edge parentEdge) =>  

  @override
  IoNodeStateImpl build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  void removeChild(Edge childEdge) {
    // TODO: implement removeChild
    throw UnimplementedError();
  }

  @override
  void removeParent(Edge parentEdge) {
    // TODO: implement removeParent
    throw UnimplementedError();
  }

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) {
    // TODO: implement updateGeometry
    throw UnimplementedError();
  }

  void addExternalParent(Edge externalParent) {
    // TODO: implement addExternalParent
    throw UnimplementedError();
  }

  void addExternalChild(Edge externalChild) {
    // TODO: implement addExternalChild
    throw UnimplementedError();
  }

  void removeExternalParent(Edge externalParent) {
    // TODO: implement removeExternalParent
    throw UnimplementedError();
  }

  void removeExternalChild(Edge externalChild) {
    // TODO: implement removeExternalChild
    throw UnimplementedError();
  }

  @override
  // TODO: implement children
  Set<Edge> get children => throw UnimplementedError();

  @override
  // TODO: implement inputEdges
  Map<InGameItem, List<Edge>> get inputEdges => throw UnimplementedError();

  @override
  // TODO: implement io
  IoNodeIo? get io => throw UnimplementedError();

  @override
  // TODO: implement nodeGeometry
  NodeGeometryImpl get nodeGeometry => throw UnimplementedError();

  @override
  // TODO: implement outputEdges
  Map<InGameItem, List<Edge>> get outputEdges => throw UnimplementedError();

  @override
  // TODO: implement parents
  Set<Edge> get parents => throw UnimplementedError();

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  void removeSelf() {
    // TODO: implement removeSelf
  }
}
