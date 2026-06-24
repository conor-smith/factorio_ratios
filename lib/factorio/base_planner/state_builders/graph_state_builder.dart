part of 'state_builders.dart';

// Due to the complexity of state interactions, I've tried to make every
// "remove...()" function still carry out all necessary actions, even if unnecessary
// eg. If graph.getStateBuilder().removeEdge(edge) is called before
// edge.getStateBuilder().removeSelf(), edgeStateBuilder.removeSelf() will still be called
class GraphStateBuilder
    implements NodeStateBuilder<GraphStateImpl>, GraphState {
  final Graph graph;

  // These booleans exist to stop loops where they might arise
  bool _removingSelf = false;

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
      _outputNodes.values.expand((node) => node.parents).toSet();
  @override
  Set<Edge> get children =>
      _inputNodes.values.expand((node) => node.children).toSet();
  @override
  Set<InGameItem> get inputItems => _inputNodes.keys.toSet();
  @override
  Set<InGameItem> get outputItems => _outputNodes.keys.toSet();

  @override
  Set<NodeElement> get allNodes => GraphState.calculateAllNodes(
    _prodLineNodes,
    _graphNodes,
    _inputNodes,
    _outputNodes,
  ).toSet();

  GraphStateBuilder.from(this.graph, GraphStateImpl previousState)
    : _name = previousState.name,
      _icon = previousState.icon,
      _prodLineNodes = Set.from(previousState.prodLineNodes),
      _graphNodes = Set.from(previousState.graphNodes),
      _inputNodes = Map.from(previousState.inputNodes),
      _outputNodes = Map.from(previousState.outputNodes),
      _edges = Set.from(previousState.edges),
      _nodeGeometry = previousState.nodeGeometry {
    graph.basePlanner.getSnapshotBuilder().addToSnapsnot(graph, this);
  }

  @override
  void addSelf() {
    if (!graph.isRoot) {
      graph.parentGraph.getStateBuilder()._addGraphNode(graph);
    }
  }

  @override
  void removeSelf() {
    if (!_removingSelf) {
      _removingSelf = true;

      graph.basePlanner.getSnapshotBuilder().removeFromSnapshot(graph);

      // When nodes are removed, they automatically remove all attached edges
      var nodesToRemove = [...allNodes];

      _prodLineNodes.clear();
      _graphNodes.clear();
      _inputNodes.clear();
      _outputNodes.clear();

      for (var node in nodesToRemove) {
        node.getStateBuilder().removeSelf();
      }

      if (!graph.parentGraph.isRoot) {
        graph.parentGraph.getStateBuilder()._removeGraphNode(graph);
      }
    }
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  void clearIo() {
    if (_io != null) {
      _io = null;

      if (!graph.isRoot) {
        graph.parentGraph.getStateBuilder().clearIo();
      }
    }
  }

  void _addProdLineNode(ProdLineNode node) {
    _prodLineNodes.add(node);
    clearIo();
  }

  void _removeProdLineNode(ProdLineNode node) {
    if (!_removingSelf) {
      node.getStateBuilder().removeSelf();
      _prodLineNodes.remove(node);
      clearIo();
    }
  }

  void _addGraphNode(Graph graphNode) {
    _graphNodes.add(graphNode);
    clearIo();
  }

  void _removeGraphNode(Graph graphNode) {
    if (!_removingSelf) {
      graphNode.getStateBuilder().removeSelf();
      _graphNodes.remove(graphNode);
    }
  }

  void _addIoNode(IoNode node) {
    if (node.nodeType == NodeType.output) {
      if (_outputNodes.containsKey(node.ioItem)) {
        throw GraphException(
          'Output node for item ${node.ioItem} in graph $graph already exists',
        );
      } else {
        _outputNodes[node.ioItem] = node;
      }
    } else {
      if (_inputNodes.containsKey(node.ioItem)) {
        throw GraphException(
          'Input node for item ${node.ioItem} in graph $graph already exists',
        );
      } else {
        _inputNodes[node.ioItem] = node;
      }
    }

    clearIo();
  }

  void _removeIoNode(IoNode node) {
    if (!_removingSelf) {
      node.getStateBuilder().removeSelf();
      if (node.nodeType == NodeType.output) {
        _outputNodes.remove(node.ioItem);
      } else {
        _inputNodes.remove(node.ioItem);
      }

      clearIo();
    }
  }

  void _addEdge(Edge edge) => _edges.add(edge);
  void _removeEdge(Edge edge) {
    if (!_removingSelf) {
      edge.getStateBuilder().removeSelf();
      _edges.remove(edge);
    }
  }

  @override
  void _addParent(Edge parent) =>
      parent.childItemNode.getStateBuilder()._addParent(parent);

  @override
  void _addChild(Edge child) =>
      child.parentItemNode.getStateBuilder()._addChild(child);

  @override
  void _removeParent(Edge parent) =>
      parent.child.getStateBuilder()._removeParent(parent);

  @override
  void _removeChild(Edge child) =>
      child.parentItemNode.getStateBuilder()._removeChild(child);

  @override
  GraphStateImpl build() => GraphStateImpl(
    graph: graph,
    icon: _icon,
    name: _name,
    prodLineNodes: _prodLineNodes,
    graphNodes: _graphNodes,
    inputNodes: _inputNodes,
    outputNodes: _outputNodes,
    edges: _edges,
    nodeGeometry: _nodeGeometry,
    io: _io,
  );
}
