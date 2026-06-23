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

  GraphStateImpl._initial({
    required this.name,
    required this.icon,
    required this.nodeGeometry,
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
         outputNodes.values.expand((node) => node.parents),
       ),
       children = Set.unmodifiable(
         inputNodes.values.expand((node) => node.children),
       ),
       inputItems = Set.unmodifiable(inputNodes.keys),
       outputItems = Set.unmodifiable(outputNodes.keys) {
    var allElements = allNodes.cast<BasePlannerElement>().followedBy(edges);
    for (var element in allElements) {
      if (element.parentGraph != graph) {
        throw GraphException(
          'Cannot add element $element with parent graph ${element.parentGraph} to graph $graph',
        );
      }
    }

    for (var edge in this.edges) {
      if (!allNodes.contains(edge.parent) || !allNodes.contains(edge.child)) {
        throw GraphException(
          'Cannot add edge $edge to graph $graph as either parent or child are not present',
        );
      }
    }

    if (graph.isRoot &&
        (this.inputNodes.isNotEmpty || this.outputNodes.isNotEmpty)) {
      throw const GraphException(
        'Root graph is not permitted to have output or input nodes',
      );
    }

    for (var inputNode in this.inputNodes.values) {
      if (inputNode.nodeType != NodeType.input) {
        throw GraphException(
          'IO node of type ${inputNode.nodeType} was incorrectly added to input nodes',
        );
      }
    }
    for (var outputNode in this.outputNodes.values) {
      if (outputNode.nodeType != NodeType.input) {
        throw GraphException(
          'IO node of type ${outputNode.nodeType} was incorrectly added to output nodes',
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

// Due to the complexity of state interactions, I've tried to make every
// "remove...()" function still carry out all necessary actions, even if unnecessary
// eg. If graph.getStateBuilder().removeEdge(edge) is called before
// edge.getStateBuilder().removeSelf(), edgeStateBuilder.removeSelf() will still be called
class GraphStateBuilder
    implements NodeStateBuilder<GraphStateImpl>, GraphState {
  final Graph _graph;

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
  Set<NodeElement> get allNodes => GraphState._calculateAllNodes(
    _prodLineNodes,
    _graphNodes,
    _inputNodes,
    _outputNodes,
  ).toSet();

  GraphStateBuilder._from(this._graph)
    : _name = _graph._state.name,
      _icon = _graph._state.icon,
      _prodLineNodes = Set.from(_graph._state.prodLineNodes),
      _graphNodes = Set.from(_graph._state.graphNodes),
      _inputNodes = Map.from(_graph.inputNodes),
      _outputNodes = Map.from(_graph.outputNodes),
      _edges = Set.from(_graph._state.edges),
      _nodeGeometry = _graph._state.nodeGeometry {
    _graph.basePlanner.getSnapshotBuilder().addToSnapsnot(_graph, this);
  }

  @override
  void addSelf() {
    if (!_graph.isRoot) {
      _graph.parentGraph.getStateBuilder().addGraphNode(_graph);
    }
  }

  @override
  void removeSelf() {
    if (!_removingSelf) {
      _removingSelf = true;

      _graph.basePlanner.getSnapshotBuilder().removeFromSnapshot(_graph);

      // When nodes are removed, they automatically remove all attached edges
      var nodesToRemove = [...allNodes];

      _prodLineNodes.clear();
      _graphNodes.clear();
      _inputNodes.clear();
      _outputNodes.clear();

      for (var node in nodesToRemove) {
        node.getStateBuilder().removeSelf();
      }

      if (!_graph.parentGraph.isRoot) {
        _graph.parentGraph.getStateBuilder().removeGraphNode(_graph);
      }
    }
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  @override
  void updateGeometry(NodeGeometryImpl nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  void addProdLineNode(ProdLineNode node) {
    _prodLineNodes.add(node);
    clearIo();
  }

  void removeProdLineNode(ProdLineNode node) {
    if (!_removingSelf) {
      node.getStateBuilder().removeSelf();
      _prodLineNodes.remove(node);
      clearIo();
    }
  }

  void addGraphNode(Graph graphNode) {
    _graphNodes.add(graphNode);
    clearIo();
  }

  void removeGraphNode(Graph graphNode) {
    if (!_removingSelf) {
      graphNode.getStateBuilder().removeSelf();
      _graphNodes.remove(graphNode);
    }
  }

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

    clearIo();
  }

  void removeIoNode(IoNode node) {
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

  void addEdge(Edge edge) => _edges.add(edge);
  void removeEdge(Edge edge) {
    if (!_removingSelf) {
      edge.getStateBuilder().removeSelf();
      _edges.remove(edge);
    }
  }

  @override
  void addParent(Edge parent) =>
      (parent.childItemNode as IoNode).getStateBuilder().addParent(parent);

  @override
  void addChild(Edge child) =>
      (child.parentItemNode as IoNode).getStateBuilder().addChild(child);

  @override
  void removeParent(Edge parent) =>
      (parent.child as IoNode).getStateBuilder().removeParent(parent);

  @override
  void removeChild(Edge child) =>
      (child.parentItemNode as IoNode).getStateBuilder().removeChild(child);

  void clearIo() {
    if (_io != null) {
      _io = null;

      if (!_graph.isRoot) {
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
    edges: _edges,
    nodeGeometry: _nodeGeometry,
    io: _io,
  );
}
