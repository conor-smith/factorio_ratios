part of 'state_builders.dart';

class GraphStateBuilder extends StateBuilder<GraphStateImpl>
    implements GraphState {
  @override
  final Graph _element;

  String _name;
  Icon? _icon;
  final Set<ProdLineNode> _prodLineNodes;
  final Set<Graph> _graphNodes;
  final Map<InGameItem, ProdLineNode> _inputNodes;
  final Map<InGameItem, ProdLineNode> _outputNodes;
  final Set<Edge> _edges;
  NodeGeometryImpl _geometry;

  GraphLayout _layout;

  Map<InGameItem, Set<Edge>>? _cachedParents;
  Map<InGameItem, Set<Edge>>? _cachedChildren;

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

  @override
  Set<InGameItem> get inputItems => _inputNodes.keys.toSet();
  @override
  Set<InGameItem> get outputItems => _outputNodes.keys.toSet();
  @override
  Map<InGameItem, Set<Edge>> get parents {
    _cachedParents ??= GraphState.calculateParents(outputNodes);
    return _cachedParents!;
  }

  @override
  Map<InGameItem, Set<Edge>> get children {
    _cachedChildren ??= GraphState.calculateChildren(inputNodes);
    return _cachedChildren!;
  }

  @override
  Set<NodeElement> get allNodes => GraphState.calculateAllNodes(
    _prodLineNodes,
    _graphNodes,
    _inputNodes,
    _outputNodes,
  ).toSet();

  @override
  GraphLayout get layout => _layout;

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

  GraphStateBuilder.initial(this._element)
    : _name = 'graph',
      _icon = _element.surface?.icon,
      _prodLineNodes = {},
      _graphNodes = {},
      _inputNodes = {},
      _outputNodes = {},
      _edges = {},
      _geometry = NodeGeometryImpl.uninitialised,
      _layout = GraphLayout.table,
      _cachedParents = {},
      _cachedChildren = {},
      super.initial() {
    if (!_element.isRoot) {
      _element.parentGraph.getStateBuilder()
        .._graphNodes.add(_element)
        .._addNodeToNodeCaches(_element);
    }
  }

  GraphStateBuilder.from(this._element, GraphStateImpl previousState)
    : _name = previousState.name,
      _icon = previousState.icon,
      _prodLineNodes = Set.from(previousState.prodLineNodes),
      _graphNodes = Set.from(previousState.graphNodes),
      _inputNodes = Map.from(previousState.inputNodes),
      _outputNodes = Map.from(previousState.outputNodes),
      _edges = Set.from(previousState.edges),
      _cachedParents = previousState.parents,
      _cachedChildren = previousState.children,
      _geometry = previousState.geometry,
      _layout = previousState.layout,
      super.from();

  @override
  void removeSelf() {
    for (var parent in parents.values.expand((edgeSet) => edgeSet)) {
      parent.getStateBuilder()._removeSelfAndUpdateParentOnly();
    }

    for (var child in children.values.expand((edgeSet) => edgeSet)) {
      child.getStateBuilder()._removeSelfAndUpdateChildOnly();
    }

    _removeSelfButNotOthers();
  }

  void removeAllNodesExceptIo() {
    _snapshotBuilder
      ..updateIoSatus(_element, UpdateStatus.checkDependencies)
      ..queueLayoutUpdate(_element);

    for (var node in _prodLineNodes) {
      node.getStateBuilder()._removeSelfButNotOthers();
    }
    for (var graphNode in _graphNodes) {
      graphNode.getStateBuilder()._removeSelfButNotOthers();
    }
    for (var edge in _edges) {
      _snapshotBuilder.removeFromSnapshot(edge);
    }

    for (var inputNode in inputNodes.values) {
      inputNode.getStateBuilder()._parents.clear();
    }
    for (var outputNode in outputNodes.values) {
      outputNode.getStateBuilder()._children.clear();
    }

    for (var ioNode in [...inputNodes.values, ...outputNodes.values]) {
      _snapshotBuilder
        ..updateIoSatus(ioNode, UpdateStatus.required)
        ..queueUnfulfilledIoCheck(ioNode);
    }

    _prodLineNodes.clear();
    _edges.clear();
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  @override
  void updateGeometry(NodeGeometryImpl geometry) {
    if (_snapshotBuilder.stage != SnapshotBuildStage.updateGraphLayouts &&
        _element.parentGraph.layout != GraphLayout.custom) {
      _element.parentGraph.getStateBuilder()._layout = GraphLayout.custom;
    }

    _geometry = geometry;
  }

  @override
  GraphStateImpl build() => GraphStateImpl(
    graph: _element,
    icon: _icon,
    name: _name,
    prodLineNodes: _prodLineNodes,
    graphNodes: _graphNodes,
    inputNodes: _inputNodes,
    outputNodes: _outputNodes,
    edges: _edges,
    geometry: _geometry,
    ioRatios: ItemIoImpl.empty, // TODO
    layout: _layout,
    ioData: GraphIo.fromState(this),
  );

  // Used when parent graph is doing bulk removal
  void _removeSelfButNotOthers() {
    _snapshotBuilder.removeFromSnapshot(_element);

    var allProdLineNodes = _prodLineNodes
        .followedBy(_inputNodes.values)
        .followedBy(_outputNodes.values);

    for (var prodLine in allProdLineNodes) {
      prodLine.getStateBuilder()._removeSelfButNotOthers();
    }
    for (var graphNode in _graphNodes) {
      graphNode.getStateBuilder()._removeSelfButNotOthers();
    }
    for (var edge in _edges) {
      _snapshotBuilder.removeFromSnapshot(edge);
    }

    _prodLineNodes.clear();
    _inputNodes.clear();
    _outputNodes.clear();
    _graphNodes.clear();
    _edges.clear();
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

  void _addNodeToNodeCaches(NodeElement node) {
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

  void _removeNodeFromNodeCaches(NodeElement node) {
    if (_cachedNodeOutputIndex != null && node.nodeType.outputPriority < 100) {
      for (var output in node.outputItems) {
        _cachedNodeOutputIndex![output]?.remove(node);
      }

      if (node.nodeType == NodeType.output && _element.parentGraph.hasBuilder) {
        _element.parentGraph.getStateBuilder()._clearCachedOutputIndex();
      }
    } else if (_cachedDisposalNodes != null &&
        node.nodeType == NodeType.disposal) {
      _clearCachedDisposalNodes();
    }
  }

  void _clearCachedOutputIndex() => _cachedNodeOutputIndex = null;
  void _clearCachedDisposalNodes() => _cachedDisposalNodes = null;
  void _clearCachedParents() => _cachedParents = null;
  void _clearCachedChildren() => _cachedChildren = null;

  int _orderByNodeType(NodeElement node1, NodeElement node2) =>
      node1.nodeType.compareTo(node2.nodeType);
}
