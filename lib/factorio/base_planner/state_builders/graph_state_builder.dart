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

  Map<InGameItem, List<NodeElement>>? _cachedNodeOutputIndex;
  Map<InGameItem, NodeElement>? _cachedDisposalNodes;

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
  // TODO
  @override
  GraphIo get ioData => throw const GraphException(
    'Graph IO cannot be calculated while snapshot is building',
  );
  @override
  ItemIoImpl get ioRatios => throw const GraphException(
    'Graph IO cannot be calculated while snapshot is building',
  );

  // TODO - Cache these values?
  @override
  Map<InGameItem, Set<Edge>> get parents =>
      GraphState.calculateParents(_outputNodes);
  @override
  Map<InGameItem, Set<Edge>> get children =>
      GraphState.calculateChildren(_outputNodes);
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

  @override
  IoUpdateStatus get ioUpdateStatus => IoUpdateStatus.complete;

  /// DO NOT modify this value outside this class
  Map<InGameItem, List<NodeElement>> get cachedNodeOutputIndex {
    _cachedNodeOutputIndex ??= _createNodeOutputIndex();

    return _cachedNodeOutputIndex!;
  }

  /// DO NOT modify this value outside this class
  Map<InGameItem, List<NodeElement>> get cachedDisposalNodes {
    _cachedDisposalNodes = _createCachedDisposalNodes();

    return _cachedNodeOutputIndex!;
  }

  GraphStateBuilder.initial(this._graph)
    : _name = 'graph',
      _icon = _graph.surface?.icon,
      _prodLineNodes = {},
      _graphNodes = {},
      _inputNodes = {},
      _outputNodes = {},
      _edges = {},
      _geometry = NodeGeometryImpl.uninitialised {
    _graph.basePlanner.getSnapshotBuilder().addToSnapshot(_graph, this);

    if (!_graph.isRoot) {
      _graph.parentGraph.getStateBuilder()._graphNodes.add(_graph);
      _graph.parentGraph.getStateBuilder()._addNodeToCaches(_graph);
    }
  }

  GraphStateBuilder.from(this._graph, GraphStateImpl previousState)
    : _name = previousState.name,
      _icon = previousState.icon,
      _prodLineNodes = Set.from(previousState.prodLineNodes),
      _graphNodes = Set.from(previousState.graphNodes),
      _inputNodes = Map.from(previousState.inputNodes),
      _outputNodes = Map.from(previousState.outputNodes),
      _edges = Set.from(previousState.edges),
      _geometry = previousState.geometry {
    _graph.basePlanner.getSnapshotBuilder().addToSnapshot(_graph, this);
  }

  @override
  void performIoUpdate() => throw const GraphException(
    'Cannot perform IO update on graph state builder',
  );
  @override
  void _queueIoUpdate() => throw const GraphException(
    'Cannot perform IO update on graph state builder',
  );

  @override
  void removeSelf() {
    _recursivelyRemoveFromSnapshot();

    var snapshotBuilder = _graph.basePlanner.getSnapshotBuilder();

    for (var parent in parents.values.expand((edgeSet) => edgeSet)) {
      snapshotBuilder.removeFromSnapshot(parent);

      parent.parentProdLine.getStateBuilder()._children[parent.item]!.remove(
        parent,
      );
      parent.getStateBuilder()._queueParentsAffectedByRemoval();

      // If parent is a graph, this just creates a new statebuilder
      // This ensures graph.children, which is determined dynamically, is updated
      parent.parent.getStateBuilder();
    }

    for (var child in children.values.expand((edgeSet) => edgeSet)) {
      snapshotBuilder.removeFromSnapshot(child);

      child.childProdLine.getStateBuilder()._parents[child.item]!.remove(child);
      child.getStateBuilder()._queueChildrenAffectedByRemoval();

      // If parent is a graph, this just creates a new statebuilder
      // This ensures graph.parents, which is determined dynamically, is updated
      child.child.getStateBuilder();
    }
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

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
    ioRatios: ItemIoImpl.empty, // TODO
    ioData: GraphIo.fromState(this),
  );

  void _recursivelyRemoveFromSnapshot() {
    var snapShotBuilder = _graph.basePlanner.getSnapshotBuilder();

    snapShotBuilder.removeFromSnapshot(_graph);

    var allProdLineNodes = _prodLineNodes
        .followedBy(_inputNodes.values)
        .followedBy(_outputNodes.values);

    for (var prodLine in allProdLineNodes) {
      snapShotBuilder.removeFromSnapshot(prodLine);
    }
    for (var edge in _edges) {
      snapShotBuilder.removeFromSnapshot(edge);
    }

    for (var graphNode in _graphNodes) {
      graphNode.getStateBuilder()._recursivelyRemoveFromSnapshot();
    }
  }

  Map<InGameItem, List<NodeElement>> _createNodeOutputIndex() {
    Map<InGameItem, List<NodeElement>> nodeOutputIndex = {};

    for (var node in allNodes.where(
      (node) => node.nodeType.outputPriority < 100,
    )) {
      for (var nodeOutput in node.outputItems) {
        _cachedNodeOutputIndex!.update(
          nodeOutput,
          (nodes) => nodes..add(node),
          ifAbsent: () => [node],
        );
      }
    }

    _cachedNodeOutputIndex!.updateAll(
      (item, nodes) => nodes..sort(_orderByNodeType),
    );

    return nodeOutputIndex;
  }

  Map<InGameItem, NodeElement> _createCachedDisposalNodes() {
    // If two disposal nodes exist for one item, this will only account for
    // one of them. This is intentional, but also means we need to clear
    // the cache every time a disposal node is removed or updated
    Map<InGameItem, NodeElement> cachedNodes = {};

    for (var node in _prodLineNodes.where(
      (node) => node.nodeType == NodeType.disposal,
    )) {
      for (var input in node.inputItems) {
        cachedNodes[input] = node;
      }
    }

    return cachedNodes;
  }

  void _addNodeToCaches(NodeElement node) {
    if (_cachedNodeOutputIndex != null && node.nodeType.outputPriority < 100) {
      for (var output in node.outputItems) {
        _cachedNodeOutputIndex!.update(
          output,
          (nodes) => nodes
            ..add(node)
            ..sort(_orderByNodeType),
          ifAbsent: () => [node],
        );
      }
    } else if (_cachedDisposalNodes != null &&
        node.nodeType == NodeType.disposal) {
      for (var input in node.inputItems) {
        _cachedDisposalNodes![input] = node;
      }
    }
  }

  void _removeNodeFromCaches(NodeElement node) {
    if (_cachedNodeOutputIndex != null && node.nodeType.outputPriority < 100) {
      for (var output in node.outputItems) {
        _cachedNodeOutputIndex![output]?.remove(node);
      }

      if (node.nodeType == NodeType.output && _graph.parentGraph.hasBuilder) {
        _graph.parentGraph.getStateBuilder()._clearCachedOutputIndex();
      }
    } else if (_cachedDisposalNodes != null &&
        node.nodeType == NodeType.disposal) {
      _clearCachedDisposalNodes();
    }
  }

  void _clearCachedOutputIndex() => _cachedNodeOutputIndex = null;
  void _clearCachedDisposalNodes() => _cachedDisposalNodes = null;

  int _orderByNodeType(NodeElement node1, NodeElement node2) =>
      node1.nodeType.compareTo(node2.nodeType);
}
