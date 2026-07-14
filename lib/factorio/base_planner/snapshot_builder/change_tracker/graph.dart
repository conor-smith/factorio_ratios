part of '../snapshot_builder.dart';

class GraphChangeTracker
    extends
        NodeChangeTracker<
          Graph,
          GraphStateImpl,
          GraphDependencies,
          GraphStateBuilder
        > {
  bool get layoutUpdate => _layoutUpdate;

  bool _layoutUpdate = false;
  Map<InGameItem, List<NodeElement>>? _cachedNodeOutputIndex;
  Map<InGameItem, NodeElement>? _cachedDisposalNodes;

  GraphChangeTracker(super.element, super.previousState);

  GraphChangeTracker.newGraph(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : super.newNode() {
    element.parentGraph.getStateBuilder()._graphNodes.add(element);
  }

  static int _orderByNodeType(NodeElement node1, NodeElement node2) =>
      node1.nodeType.compareTo(node2.nodeType);

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

  void queueLayoutUpdate() => _layoutUpdate = true;

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

    List<BasePlannerElement> allElements = [
      ...state.inputNodes.values,
      ...state.outputNodes.values,
      ...state.prodLineNodes,
      ...state.graphNodes,
      ...state.edges,
    ];

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
  bool calculateIo() {
    var builder = GraphIoBuilder();

    for (var node in state.allNodes) {
      builder.add(node);
    }

    stateBuilder.updateIoData(builder.build());

    return true;
  }

  @override
  Iterable<Graph> determineDependants() {
    if (element.isRoot) {
      return const [];
    } else {
      return [element.parentGraph];
    }
  }

  void removeAllNodesExceptIo() {
    queueIoUpdate();
    queueLayoutUpdate();

    _clearCachedDisposalNodes();
    _clearCachedOutputIndex();

    List<BasePlannerElement> elementsToRemove = [
      ...state.prodLineNodes,
      ...state.graphNodes,
      ...state.edges,
    ];
    for (var element in elementsToRemove) {
      element.getChangeTracker()._removeSelfOnly();
    }

    for (var inputNode in state.inputNodes.values) {
      inputNode.getStateBuilder()._parents.clear();
    }
    for (var outputNode in state.outputNodes.values) {
      outputNode.getStateBuilder()._children.clear();
    }

    for (var ioNode in [
      ...state.inputNodes.values,
      ...state.outputNodes.values,
    ]) {
      ioNode.getChangeTracker()
        ..queueIoUpdate()
        ..queueUnusedIoCheck();
    }

    stateBuilder
      .._prodLineNodes.clear()
      .._graphNodes.clear()
      .._edges.clear();
  }

  void performLayoutUptdate() {
    // TODO
    throw UnimplementedError();
  }

  @override
  GraphDependencies _determineDependencies() =>
      GraphDependencies(state.allNodes);

  @override
  GraphStateBuilder _createStateBuilder() =>
      GraphStateBuilder.from(previousState);

  @override
  void _removeSelfOnly() {
    _toRemove = true;
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
