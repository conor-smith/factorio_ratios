part of 'change_trackers.dart';

class GraphChangeTracker
    extends
        NodeChangeTracker<
          Graph,
          GraphStateImpl,
          GraphDependencies,
          GraphStateBuilder
        > {
  bool get layoutUpdateQueued => _layoutUpdateQueued;

  bool _layoutUpdateQueued = false;
  Map<InGameItem, List<NodeElement>>? _cachedNodeOutputIndex;
  Map<InGameItem, NodeElement>? _cachedDisposalNodes;

  static int _orderByNodeType(NodeElement node1, NodeElement node2) =>
      node1.nodeType.compareTo(node2.nodeType);

  GraphChangeTracker(super.element, super.previousState) {
    snapshotBuilder._graphTrackers[element] = this;
  }

  GraphChangeTracker.newGraph(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : super.newNode() {
    snapshotBuilder._graphTrackers[element] = this;
    element.parentGraph.getChangeTracker()._addNodeToNodeCaches(element);

    element.parentGraph.getStateBuilder()._graphNodes.add(element);
  }

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

  void queueLayoutUpdate() => _layoutUpdateQueued = true;

  @override
  GraphState get state => _cachedStateBuilder ?? previousState;

  @override
  void removeSelf() {
    for (var parent in state.allParents) {
      parent.getChangeTracker()._removeSelfFromParentOnly();
    }

    for (var child in state.allChildren) {
      child.getChangeTracker()._removeSelfFromChildOnly();
    }

    var allElements = Iterable<BasePlannerElement>.empty()
        .followedBy(state.inputNodes.values)
        .followedBy(state.outputNodes.values)
        .followedBy(state.prodLineNodes)
        .followedBy(state.graphNodes)
        .followedBy(state.edges);

    for (var element in allElements) {
      element.getChangeTracker()._removeSelfOnly();
    }

    element.parentGraph.getChangeTracker().stateBuilder._graphNodes.remove(
      element,
    );

    _removeSelfAndUpdateParentGraphSnapshotBuilder();
    _removeSelfOnly();
  }

  @override
  Iterable<Graph> _determineDependants() {
    if (element.isRoot) {
      return const [];
    } else {
      return [element.parentGraph];
    }
  }

  void removeAllNodesExceptIo() {
    if (state.prodLineNodes.isEmpty &&
        state.graphNodes.isEmpty &&
        state.edges.isEmpty) {
      return;
    }

    queueIoUpdate();
    queueLayoutUpdate();

    _clearCachedDisposalNodes();
    _clearCachedOutputIndex();

    var elementsToRemove = Iterable<BasePlannerElement>.empty()
        .followedBy(state.prodLineNodes)
        .followedBy(state.graphNodes)
        .followedBy(state.edges);

    for (var element in elementsToRemove) {
      element.getChangeTracker()._removeSelfOnly();
    }

    for (var inputNode in state.inputNodes.values) {
      inputNode.getStateBuilder()._parents.clear();
    }
    for (var outputNode in state.outputNodes.values) {
      outputNode.getStateBuilder()._children.clear();
    }

    for (var ioNode in state.inputNodes.values.followedBy(
      state.outputNodes.values,
    )) {
      ioNode.getChangeTracker()
        ..queueIoUpdate()
        ..queueUnusedIoCheck();
    }

    stateBuilder
      .._prodLineNodes.clear()
      .._graphNodes.clear()
      .._edges.clear();
  }

  @override
  bool _calculateIo() {
    var builder = GraphIoBuilder();

    for (var node in state.allNodes) {
      builder.add(node);
    }

    var newIoData = builder.build();
    stateBuilder._updateIoData(newIoData);

    return true;
  }

  void _performLayoutUpdate() {
    element.layoutNodes();
    _layoutUpdateQueued = false;
  }

  @override
  GraphDependencies _determineDependencies() =>
      GraphDependencies(state.allNodes);

  @override
  GraphStateBuilder _createStateBuilder() =>
      GraphStateBuilder.from(element, previousState);

  @override
  void _removeSelfOnly() {
    _queuedForRemoval = true;
    _clearCachedDisposalNodes();
    _clearCachedOutputIndex();

    stateBuilder
      .._edges.clear()
      .._prodLineNodes.clear()
      .._graphNodes.clear()
      .._inputNodes.clear()
      .._outputNodes.clear()
      .._cachedChildren = const {}
      .._cachedParents = const {};
  }

  Map<InGameItem, List<NodeElement>> _createNodeOutputIndex() {
    Map<InGameItem, List<NodeElement>> nodeOutputIndex = {};

    for (var node in state.allNodes.where(
      (node) => node.nodeType.outputPriority < 100,
    )) {
      for (var nodeOutput in node.outputItems) {
        nodeOutputIndex.update(
          nodeOutput,
          (nodes) => nodes..add(node),
          ifAbsent: () => [node],
        );
      }
    }

    nodeOutputIndex.updateAll((item, nodes) => nodes..sort(_orderByNodeType));

    return nodeOutputIndex;
  }

  Map<InGameItem, NodeElement> _createCachedDisposalNodes() {
    // If two disposal nodes exist for one item, this will only account for
    // one of them. This is intentional, but also means we need to clear
    // the cache every time a disposal node is removed or updated
    Map<InGameItem, NodeElement> cachedNodes = {};

    for (var node in state.prodLineNodes.where(
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
            ..sort(GraphChangeTracker._orderByNodeType),
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

      if (node.nodeType == NodeType.output) {
        element.parentGraph.getChangeTracker()._clearCachedOutputIndex();
      }
    } else if (_cachedDisposalNodes != null &&
        node.nodeType == NodeType.disposal) {
      _clearCachedDisposalNodes();
    }
  }

  void _clearCachedOutputIndex() => _cachedNodeOutputIndex = null;
  void _clearCachedDisposalNodes() => _cachedDisposalNodes = null;
}

class GraphDependencies implements Dependencies {
  final Set<NodeElement> allNodes;

  GraphDependencies(this.allNodes);

  @override
  Iterable<BasePlannerElement> get allElements => allNodes;
}
