part of 'state_builders.dart';

// Due to the complexity of state interactions, I've tried to make every
// "remove...()" function still carry out all necessary actions, even if unnecessary
// eg. If graph.getStateBuilder().removeEdge(edge) is called before
// edge.getStateBuilder().removeSelf(), edgeStateBuilder.removeSelf() will still be called
class GraphStateBuilder
    implements NodeStateBuilder<GraphStateImpl>, GraphState {
  final Graph _graph;

  String _name;
  Icon? _icon;
  final Set<ProdLineNode> _prodLineNodes;
  final Set<Graph> _graphNodes;
  final Map<InGameItem, ProdLineNode> _inputNodes;
  final Map<InGameItem, ProdLineNode> _outputNodes;
  final Set<Edge> _edges;
  NodeGeometryImpl _geometry;
  GraphIo _io;

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
  late final Map<InGameItem, ProdLineNode> inputNodes = UnmodifiableMapView(
    _inputNodes,
  );
  @override
  late final Map<InGameItem, ProdLineNode> outputNodes = UnmodifiableMapView(
    _outputNodes,
  );
  @override
  late final Set<Edge> edges = UnmodifiableSetView(_edges);
  @override
  NodeGeometryImpl get geometry => _geometry;
  @override
  GraphIo get io => _io;

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

  GraphStateBuilder.from(this._graph, GraphStateImpl previousState)
    : _name = previousState.name,
      _icon = previousState.icon,
      _prodLineNodes = Set.from(previousState.prodLineNodes),
      _graphNodes = Set.from(previousState.graphNodes),
      _inputNodes = Map.from(previousState.inputNodes),
      _outputNodes = Map.from(previousState.outputNodes),
      _edges = Set.from(previousState.edges),
      _geometry = previousState.geometry,
      _io = previousState.io {
    _graph.basePlanner.getSnapshotBuilder().addToSnapsnot(_graph, this);
  }

  @override
  void addSelf() {
    if (!_graph.isRoot) {
      _graph.parentGraph.getStateBuilder()._addGraphNode(_graph);
    }
  }

  @override
  void removeSelf() {
    _removeAllElementsAndSelfFromSnapshot();

    if (!_graph.isRoot) {
      _graph.parentGraph.getStateBuilder()._removeGraphNode(_graph);
    }
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

  void calculateIo() => _io = _graph.calculate(ItemIo.empty);

  @override
  GraphStateImpl build() => GraphStateImpl(
    graph: _graph,
    icon: _icon,
    name: _name,
    prodLineNodes: _prodLineNodes,
    graphNodes: _graphNodes,
    inputNodes: _inputNodes,
    outputNodes: _outputNodes,
    edges: _edges,
    geometry: _geometry,
    io: _io,
  );

  @override
  void _parentGraphRemoval() => _removeAllElementsAndSelfFromSnapshot();

  void _addProdLineNode(ProdLineNode node) => _prodLineNodes.add(node);
  void _removeProdLineNode(ProdLineNode node) => _prodLineNodes.remove(node);

  void _addGraphNode(Graph graphNode) => _graphNodes.add(graphNode);
  void _removeGraphNode(Graph graphNode) => _graphNodes.remove(graphNode);

  void _addInputNode(ProdLineNode node, InGameItem item) {
    if (_inputNodes.containsKey(item)) {
      throw GraphException('Input node for item $item already exists');
    }

    _inputNodes[item] = node;
  }

  void _addOutputNode(ProdLineNode node, InGameItem item) {
    if (_outputNodes.containsKey(item)) {
      throw GraphException('Output node for item $item already exists');
    }

    _outputNodes[item] = node;
  }

  void _removeInputNode(InGameItem item) => _inputNodes.remove(item);
  void _removeOutputNode(InGameItem item) => _outputNodes.remove(item);

  void _addEdge(Edge edge) => _edges.add(edge);
  void _removeEdge(Edge edge) => _edges.remove(edge);

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

  void _removeAllElementsAndSelfFromSnapshot() {
    for (var edge in [...parents, ...children]) {
      edge.getStateBuilder().removeSelf();
    }
    for (BasePlannerElement element in [...allNodes, ...edges]) {
      element.getStateBuilder()._parentGraphRemoval();
    }

    _prodLineNodes.clear();
    _inputNodes.clear();
    _outputNodes.clear();
    _graphNodes.clear();
    _edges.clear();

    _graph.basePlanner.getSnapshotBuilder().removeFromSnapshot(_graph);
  }
}
