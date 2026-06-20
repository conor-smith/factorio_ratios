part of 'graph.dart';

abstract class GraphState {
  String get name;
  Icon? get icon;
  Set<ProdLineNode> get prodLineNodes;
  Set<Graph> get graphNodes;
  Set<NodeElement> get allNodes;
  Set<Edge> get edges;
  NodeGeometryImpl get nodeGeometry;
  Set<Edge> get parents;
  Set<Edge> get children;
  Map<InGameItem, List<Edge>> get outputEdges;
  Map<InGameItem, List<Edge>> get inputEdges;
  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;
  GraphIo? get io;
}

class GraphStateImpl implements GraphState, ToJson {
  @override
  final String name;
  @override
  final Icon? icon;
  @override
  final Set<ProdLineNode> prodLineNodes;
  @override
  final Set<Graph> graphNodes;
  @override
  final Set<Edge> edges;
  @override
  final NodeGeometryImpl nodeGeometry;
  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;
  @override
  final Set<InGameItem> inputItems;
  @override
  final Set<InGameItem> outputItems;
  @override
  final GraphIo? io;

  @override
  late final Set<NodeElement> allNodes = Set.unmodifiable({
    ...prodLineNodes,
    ...graphNodes,
  });
  @override
  late final Map<InGameItem, List<Edge>> outputEdges =
      NodeElement.calculateOutputEdges(parents, children);
  @override
  late final Map<InGameItem, List<Edge>> inputEdges =
      NodeElement.calculateInputEdges(parents, children);

  GraphStateImpl._initial({
    this.name = 'graph',
    this.icon,
    this.nodeGeometry = NodeGeometryImpl.uninitialised,
  }) : prodLineNodes = const {},
       graphNodes = const {},
       edges = const {},
       parents = const {},
       children = const {},
       inputItems = const {},
       outputItems = const {},
       io = null;

  GraphStateImpl._({
    required Graph graph,
    required this.name,
    required this.icon,
    required Iterable<ProdLineNode> prodLineNodes,
    required Iterable<Graph> graphNodes,
    required Iterable<Edge> edges,
    required this.nodeGeometry,
    required Iterable<Edge> parents,
    required Iterable<Edge> children,
    required Iterable<InGameItem> inputItems,
    required Iterable<InGameItem> outputItems,
    required this.io,
  }) : prodLineNodes = Set.unmodifiable(prodLineNodes),
       graphNodes = Set.unmodifiable(graphNodes),
       edges = Set.unmodifiable(edges),
       parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children),
       inputItems = Set.unmodifiable(inputItems),
       outputItems = Set.unmodifiable(outputItems);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder
    implements NodeStateBuilder<GraphStateImpl>, GraphState {
  final Graph _graph;

  String _name;
  Icon? _icon;
  final Set<ProdLineNode> _prodLineNodes;
  final Set<Edge> _edges;
  final Set<Graph> _graphNodes;
  NodeGeometryImpl _nodeGeometry;
  final Set<Edge> _parents;
  final Set<Edge> _children;
  final Set<InGameItem> _inputItems;
  final Set<InGameItem> _outputItems;
  GraphIo? _io;

  Map<InGameItem, List<Edge>>? _cachedInputEdges;
  Map<InGameItem, List<Edge>>? _cachedOutputEdges;

  @override
  String get name => _name;
  @override
  Icon? get icon => _icon;
  @override
  late final Set<ProdLineNode> prodLineNodes = UnmodifiableSetView(
    _prodLineNodes,
  );
  @override
  late final Set<Edge> edges = UnmodifiableSetView(_edges);
  @override
  late final Set<Graph> graphNodes = UnmodifiableSetView(_graphNodes);
  @override
  NodeGeometryImpl get nodeGeometry => _nodeGeometry;
  @override
  Set<Edge> get parents => UnmodifiableSetView(_parents);
  @override
  Set<Edge> get children => UnmodifiableSetView(_children);
  @override
  Set<InGameItem> get inputItems => UnmodifiableSetView(_inputItems);
  @override
  Set<InGameItem> get outputItems => UnmodifiableSetView(_outputItems);
  @override
  GraphIo? get io => _io;

  @override
  Set<NodeElement> get allNodes => {..._prodLineNodes, ..._graphNodes};

  @override
  Map<InGameItem, List<Edge>> get inputEdges {
    _cachedInputEdges ??= NodeElement.calculateInputEdges(parents, children);
    return _cachedInputEdges!;
  }

  @override
  Map<InGameItem, List<Edge>> get outputEdges {
    _cachedOutputEdges ??= NodeElement.calculateOutputEdges(parents, children);
    return _cachedOutputEdges!;
  }

  factory GraphStateBuilder._new(Graph graph) {
    var builder = GraphStateBuilder._from(graph);

    var parentGraph = graph.parentGraph;
    if (parentGraph != graph) {
      parentGraph.getStateBuilder()
        ..addChildGraph(graph)
        ..clearIo();
    }

    return builder;
  }

  static void _remove(Graph graph) {
    graph._basePlanner.getSnapshotBuilder().removeFromSnapshot(graph);

    for (var edge in [...graph.edges]) {
      edge.remove();
    }
    for (var node in [...graph.allNodes]) {
      node.remove();
    }

    var parentGraph = graph.parentGraph;
    if (parentGraph != graph) {
      parentGraph.getStateBuilder()
        ..removeChildGraph(graph)
        ..clearIo();
    }
  }

  GraphStateBuilder._from(this._graph)
    : _name = _graph._state.name,
      _icon = _graph._state.icon,
      _prodLineNodes = Set.from(_graph._state.prodLineNodes),
      _edges = Set.from(_graph._state.edges),
      _graphNodes = Set.from(_graph._state.graphNodes),
      _nodeGeometry = _graph._state.nodeGeometry,
      _parents = Set.from(_graph._state.parents),
      _children = Set.from(_graph._state.children),
      _inputItems = Set.from(_graph._state.inputItems),
      _outputItems = Set.from(_graph._state.outputItems) {
    _graph._basePlanner.getSnapshotBuilder().addToSnapsnot(_graph, this);
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  void addNode(ProdLineNode node) => _prodLineNodes.add(node);
  void removeNode(ProdLineNode node) => _prodLineNodes.remove(node);

  void addEdge(Edge edge) => _edges.add(edge);
  void removeEdge(Edge edge) => _edges.remove(edge);

  void addChildGraph(Graph childGraph) => _graphNodes.add(childGraph);
  void removeChildGraph(Graph childGraph) => _graphNodes.remove(childGraph);

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  void addParent(Edge parent) {
    _parents.add(parent);
    _invalidateCache();
  }

  @override
  void addChild(Edge child) {
    _children.add(child);
    _invalidateCache();
  }

  @override
  void removeParent(Edge parent) {
    _parents.remove(parent);
    _invalidateCache();
  }

  @override
  void removeChild(Edge child) {
    _children.remove(child);
    _invalidateCache();
  }

  void addOutputItems(Iterable<InGameItem> outputs) =>
      _outputItems.addAll(outputs);
  void addInputItems(Iterable<InGameItem> inputs) => _inputItems.addAll(inputs);
  void removeOutputItems(Iterable<InGameItem> outputs) =>
      _outputItems.removeAll(outputs);
  void removeInputItems(Iterable<InGameItem> inputs) =>
      _inputItems.removeAll(inputs);

  void clearIo() {
    if (_io != null) {
      _io = null;

      Graph? parentGraph = _graph.parentGraph;
      while (parentGraph != null) {
        parentGraph.getStateBuilder().clearIo();
        parentGraph = parentGraph.parentGraph;
      }
    }
  }

  @override
  GraphStateImpl build() => GraphStateImpl._(
    graph: _graph,
    icon: _icon,
    name: _name,
    prodLineNodes: _prodLineNodes,
    edges: edges,
    graphNodes: _graphNodes,
    nodeGeometry: _nodeGeometry,
    parents: _parents,
    children: _children,
    inputItems: inputItems,
    outputItems: outputItems,
    io: io,
  );

  void _invalidateCache() {
    _cachedInputEdges = null;
    _cachedOutputEdges = null;
  }
}
