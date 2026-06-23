part of 'graph.dart';

abstract class GraphState {
  String get name;
  Icon? get icon;
  Set<ProdLineNode> get prodLineNodes;
  Set<Graph> get graphNodes;
  Map<InGameItem, IoNode> get inputNodes;
  Map<InGameItem, IoNode> get outputNodes;
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

  static Iterable<NodeElement> _calculateAllNodes(
    Iterable<ProdLineNode> prodLineNodes,
    Iterable<Graph> graphNodes,
    Map<InGameItem, IoNode> inputNodes,
    Map<InGameItem, IoNode> outputNodes,
  ) => prodLineNodes
      .cast<NodeElement>()
      .followedBy(graphNodes)
      .followedBy(inputNodes.values)
      .followedBy(outputNodes.values);

  static Iterable<Edge> _calculateParents(
    Map<InGameItem, IoNode> inputNodes,
    Map<InGameItem, IoNode> outputNodes,
  ) => inputNodes.values
      .followedBy(outputNodes.values)
      .expand((ioNode) => ioNode.externalParents);

  static Iterable<Edge> _calculateChildren(
    Map<InGameItem, IoNode> inputNodes,
    Map<InGameItem, IoNode> outputNodes,
  ) => inputNodes.values
      .followedBy(outputNodes.values)
      .expand((ioNode) => ioNode.externalChildren);
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
  final Map<InGameItem, IoNode> inputNodes;
  @override
  final Map<InGameItem, IoNode> outputNodes;
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
  final Set<NodeElement> allNodes;
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
       inputNodes = const {},
       outputNodes = const {},
       edges = const {},
       parents = const {},
       children = const {},
       inputItems = const {},
       outputItems = const {},
       allNodes = const {},
       io = null;

  GraphStateImpl._({
    required Graph graph,
    required this.name,
    required this.icon,
    required Iterable<ProdLineNode> prodLineNodes,
    required Iterable<Graph> graphNodes,
    required Iterable<Edge> edges,
    required Map<InGameItem, IoNode> inputNodes,
    required Map<InGameItem, IoNode> outputNodes,
    required this.nodeGeometry,
    required this.io,
  }) : prodLineNodes = Set.unmodifiable(prodLineNodes),
       graphNodes = Set.unmodifiable(graphNodes),
       edges = Set.unmodifiable(edges),
       inputNodes = Map.unmodifiable(inputNodes),
       outputNodes = Map.unmodifiable(outputNodes),
       allNodes = Set.unmodifiable(
         GraphState._calculateAllNodes(
           prodLineNodes,
           graphNodes,
           inputNodes,
           outputNodes,
         ),
       ),
       parents = Set.unmodifiable(
         GraphState._calculateParents(inputNodes, outputNodes),
       ),
       children = Set.unmodifiable(
         GraphState._calculateChildren(inputNodes, outputNodes),
       ),
       inputItems = Set.unmodifiable(inputNodes.keys),
       outputItems = Set.unmodifiable(outputNodes.keys);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder
    implements NodeStateBuilder<GraphStateImpl>, GraphState {
  final Graph _graph;

  bool toRemove = false;

  String _name;
  Icon? _icon;
  final Set<ProdLineNode> _prodLineNodes;
  final Set<Graph> _graphNodes;
  final Map<InGameItem, IoNode> _inputNodes;
  final Map<InGameItem, IoNode> _outputNodes;
  final Set<Edge> _edges;
  NodeGeometryImpl _nodeGeometry;
  GraphIo? _io;

  @override
  String get name => _name;
  @override
  Icon? get icon => _icon;
  @override
  late final Set<ProdLineNode> prodLineNodes = UnmodifiableSetView(
    _prodLineNodes,
  );
  @override
  late final Set<Graph> graphNodes = UnmodifiableSetView(_graphNodes);
  @override
  late final Map<InGameItem, IoNode> inputNodes = UnmodifiableMapView(
    _inputNodes,
  );
  @override
  late final Map<InGameItem, IoNode> outputNodes = UnmodifiableMapView(
    _outputNodes,
  );
  @override
  late final Set<Edge> edges = UnmodifiableSetView(_edges);
  @override
  NodeGeometryImpl get nodeGeometry => _nodeGeometry;
  @override
  GraphIo? get io => _io;

  // TODO - Cache these values
  @override
  Set<Edge> get parents =>
      GraphState._calculateParents(_inputNodes, _outputNodes).toSet();
  @override
  Set<Edge> get children =>
      GraphState._calculateChildren(_inputNodes, outputNodes).toSet();
  @override
  Set<InGameItem> get inputItems => _inputNodes.keys.toSet();
  @override
  Set<InGameItem> get outputItems => _outputNodes.keys.toSet();

  @override
  Set<NodeElement> get allNodes => GraphState._calculateAllNodes(
    _prodLineNodes,
    _graphNodes,
    _inputNodes,
    _outputNodes,
  ).toSet();

  @override
  Map<InGameItem, List<Edge>> get inputEdges =>
      NodeElement.calculateInputEdges(parents, children);

  @override
  Map<InGameItem, List<Edge>> get outputEdges =>
      NodeElement.calculateOutputEdges(parents, children);

  factory GraphStateBuilder._new(Graph graph) {
    var builder = GraphStateBuilder._from(graph);

    var parentGraph = graph.parentGraph;
    if (parentGraph != graph) {
      parentGraph.getStateBuilder()
        ..addGraphNode(graph)
        ..clearIo();
    }

    return builder;
  }

  static void _remove(Graph graph) {
    for (BasePlannerElement element in [...graph.allNodes, ...graph.edges]) {
      element.remove();
    }

    var parentGraph = graph.parentGraph;
    if (parentGraph != graph) {
      parentGraph.getStateBuilder()
        ..removeGraphNode(graph)
        ..clearIo();
    }
  }

  GraphStateBuilder._from(this._graph)
    : _name = _graph._state.name,
      _icon = _graph._state.icon,
      _prodLineNodes = Set.from(_graph._state.prodLineNodes),
      _graphNodes = Set.from(_graph._state.graphNodes),
      _inputNodes = Map.from(_graph.inputNodes),
      _outputNodes = Map.from(_graph.outputNodes),
      _edges = Set.from(_graph._state.edges),
      _nodeGeometry = _graph._state.nodeGeometry {
    _graph._basePlanner.getSnapshotBuilder().addToSnapsnot(_graph, this);
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  void addProdLineNode(ProdLineNode node) => _prodLineNodes.add(node);
  void removeProdLineNode(ProdLineNode node) => _prodLineNodes.remove(node);

  void addIoNode(IoNode node) {
    if (node.nodeType == NodeType.output) {
      if (_outputNodes.containsKey(node.ioItem)) {
        throw GraphException(
          'Output node for item ${node.ioItem} in graph $_graph already exists',
        );
      } else {
        _outputNodes[node.ioItem] = node;
      }
    } else {
      if (_inputNodes.containsKey(node.ioItem)) {
        throw GraphException(
          'Input node for item ${node.ioItem} in graph $_graph already exists',
        );
      } else {
        _inputNodes[node.ioItem] = node;
      }
    }
  }

  void removeIoNode(IoNode node) {
    if (node.nodeType == NodeType.output) {
      _outputNodes.remove(node.ioItem);
    } else {
      _inputNodes.remove(node.ioItem);
    }
  }

  void addEdge(Edge edge) => _edges.add(edge);
  void removeEdge(Edge edge) => _edges.remove(edge);

  void addGraphNode(Graph childGraph) => _graphNodes.add(childGraph);
  void removeGraphNode(Graph childGraph) => _graphNodes.remove(childGraph);

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  void addParent(Edge parent) => (parent.childItemNode as IoNode)
      .getStateBuilder()
      .addExternalParent(parent);

  @override
  void addChild(Edge child) => (child.parentItemNode as IoNode)
      .getStateBuilder()
      .addExternalChild(child);

  @override
  void removeParent(Edge parent) => (parent.childItemNode as IoNode)
      .getStateBuilder()
      .removeExternalParent(parent);

  @override
  void removeChild(Edge child) => (child.parentItemNode as IoNode)
      .getStateBuilder()
      .removeExternalChild(child);

  void clearIo() {
    if (_io != null) {
      _io = null;

      if (_graph != _graph._basePlanner.rootGraph) {
        _graph.parentGraph.getStateBuilder().clearIo();
      }
    }
  }

  @override
  GraphStateImpl build() => GraphStateImpl._(
    graph: _graph,
    icon: _icon,
    name: _name,
    prodLineNodes: _prodLineNodes,
    graphNodes: _graphNodes,
    inputNodes: _inputNodes,
    outputNodes: _outputNodes,
    edges: edges,
    nodeGeometry: _nodeGeometry,
    io: io,
  );
}
