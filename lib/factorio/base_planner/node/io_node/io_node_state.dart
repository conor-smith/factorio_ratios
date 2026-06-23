part of 'io_node.dart';


abstract class IoNodeState {
  IoNodeIo? get io;
  String get name;

  NodeGeometryImpl get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;

  Map<InGameItem, List<Edge>> get outputEdges;
  Map<InGameItem, List<Edge>> get inputEdges;
}

class IoNodeStateImpl implements IoNodeState, ToJson {
  @override
  final IoNodeIo? io;
  @override
  final String name;

  @override
  final NodeGeometryImpl nodeGeometry;

  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  @override
  late final Map<InGameItem, List<Edge>> outputEdges =
      NodeElement.calculateOutputEdges(parents, children);
  @override
  late final Map<InGameItem, List<Edge>> inputEdges =
      NodeElement.calculateInputEdges(parents, children);

  IoNodeStateImpl._({
    this.io,
    required this.name,
    this.nodeGeometry = NodeGeometryImpl.uninitialised,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
  }) : parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class IoNodeStateBuilder
    implements NodeStateBuilder<IoNodeStateImpl>, IoNodeState {
  @override
  void addChild(Edge chidEdge) {
    // TODO: implement addChild
    throw UnimplementedError();
  }

  @override
  void addParent(Edge parentEdge) {
    // TODO: implement addParent
    throw UnimplementedError();
  }

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