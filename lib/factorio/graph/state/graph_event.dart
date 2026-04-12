part of '../../graph.dart';

class GraphEvent extends MutationEvent {
  final BaseGraph graph;

  final Set<GraphEventType> mutations;

  final ProdLineNode? oldTopNode,
      oldLeftNode,
      oldBottomNode,
      oldRightNode,
      newTopNode,
      newLeftNode,
      newBottomNode,
      newRightNode;

  final Set<ProdLineNode> newNodes, removedNodes;
  final Set<DirectedEdge> newEdges, removedEdges;
  final Set<ItemData> newInputs, newOutputs, removedInputs, removedOutputs;

  final bool isReversed;
  final GraphEvent? original;
  late final GraphEvent reversed = original ?? GraphEvent._reverse(this);

  GraphEvent.newNode(BaseGraph graph, ProdLineNode newNode)
    : this._(graph, {GraphEventType.updateNodes}, newNodes: {newNode});

  GraphEvent.removeNode(BaseGraph graph, ProdLineNode removedNode)
    : this._(graph, {GraphEventType.updateNodes}, removedNodes: {removedNode});

  GraphEvent.newEdge(BaseGraph graph, DirectedEdge newEdge)
    : this._(graph, {GraphEventType.updateEdges}, newEdges: {newEdge});

  GraphEvent.removeEdge(BaseGraph graph, DirectedEdge removedEdge)
    : this._(graph, {GraphEventType.updateEdges}, removedEdges: {removedEdge});

  GraphEvent.newInput(BaseGraph graph, ItemData newInput)
    : this._(graph, {GraphEventType.updateInput}, newInputs: {newInput});

  GraphEvent.removeInput(BaseGraph graph, ItemData removedInput)
    : this._(
        graph,
        {GraphEventType.updateInput},
        removedInputs: {removedInput},
      );

  GraphEvent.newOutput(BaseGraph graph, ItemData newOutput)
    : this._(graph, {GraphEventType.updateOutput}, newOutputs: {newOutput});

  GraphEvent.removeOutput(BaseGraph graph, ItemData removedOutput)
    : this._(
        graph,
        {GraphEventType.updateOutput},
        removedOutputs: {removedOutput},
      );

  GraphEvent.newPositionalNodes(
    BaseGraph graph, {
    required ProdLineNode newTopNode,
    required ProdLineNode newLeftNode,
    required ProdLineNode newBottomNode,
    required ProdLineNode newRightNode,
  }) : this._(
         graph,
         {GraphEventType.positionalNodesUpdate},
         oldTopNode: graph._top,
         oldLeftNode: graph._left,
         oldBottomNode: graph._bottom,
         oldRightNode: graph._right,
         newTopNode: newTopNode,
         newLeftNode: newLeftNode,
         newBottomNode: newBottomNode,
         newRightNode: newRightNode,
       );

  GraphEvent.clearPositionalNodes(BaseGraph graph)
    : this._(
        graph,
        {GraphEventType.positionalNodesUpdate},
        oldTopNode: graph._top,
        oldLeftNode: graph._left,
        oldBottomNode: graph._bottom,
        oldRightNode: graph._right,
      );

  factory GraphEvent.combine(List<GraphEvent> orderedEvents) {
    Set<GraphEventType> mutations = {};

    Set<ProdLineNode> newNodes = {};
    Set<ProdLineNode> removedNodes = {};
    Set<DirectedEdge> newEdges = {};
    Set<DirectedEdge> removedEdges = {};

    Set<ItemData> newInputs = {};
    Set<ItemData> removedInputs = {};
    Set<ItemData> newOutputs = {};
    Set<ItemData> removedOutputs = {};

    GraphEvent? oldPositionEvent, newPositionEvent;
    ProdLineNode? oldTop,
        oldLeft,
        oldBottom,
        oldRight,
        newTop,
        newLeft,
        newBottom,
        newRight;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case GraphEventType.positionalNodesUpdate:
            oldPositionEvent ??= event;
            newPositionEvent = event;

          case GraphEventType.updateNodes:
            newNodes.addAll(event.newNodes);
            removedNodes.addAll(event.removedNodes);

          case GraphEventType.updateEdges:
            newEdges.addAll(event.newEdges);
            removedEdges.addAll(event.removedEdges);

          case GraphEventType.updateInput:
            newInputs.addAll(event.newInputs);
            removedInputs.addAll(event.removedInputs);

          case GraphEventType.updateOutput:
            newOutputs.addAll(event.newOutputs);
            removedOutputs.addAll(event.removedOutputs);
        }
      }
    }

    if (oldPositionEvent != null) {
      oldTop = oldPositionEvent.oldTopNode;
      oldLeft = oldPositionEvent.oldLeftNode;
      oldBottom = oldPositionEvent.oldBottomNode;
      oldRight = oldPositionEvent.oldRightNode;
      newTop = newPositionEvent!.newTopNode;
      newLeft = newPositionEvent.newLeftNode;
      newBottom = newPositionEvent.newBottomNode;
      newRight = newPositionEvent.newRightNode;
    }

    _removedWhereBothContain(newNodes, removedNodes);
    _removedWhereBothContain(newEdges, removedEdges);
    _removedWhereBothContain(newInputs, removedInputs);
    _removedWhereBothContain(newOutputs, removedOutputs);

    return GraphEvent._(
      orderedEvents.first.graph,
      mutations,
      newNodes: newNodes,
      newEdges: newEdges,
      newInputs: newInputs,
      newOutputs: newOutputs,
      newTopNode: newTop,
      newLeftNode: newLeft,
      newBottomNode: newBottom,
      newRightNode: newRight,
      removedNodes: removedNodes,
      removedEdges: removedEdges,
      removedInputs: removedInputs,
      removedOutputs: removedOutputs,
      oldTopNode: oldTop,
      oldLeftNode: oldLeft,
      oldBottomNode: oldBottom,
      oldRightNode: oldRight,
    );
  }

  GraphEvent._(
    this.graph,
    Set<GraphEventType> mutations, {
    this.oldTopNode,
    this.oldLeftNode,
    this.oldBottomNode,
    this.oldRightNode,
    Set<ProdLineNode> removedNodes = const {},
    Set<DirectedEdge> removedEdges = const {},
    Set<ItemData> removedInputs = const {},
    Set<ItemData> removedOutputs = const {},
    this.newTopNode,
    this.newLeftNode,
    this.newBottomNode,
    this.newRightNode,
    Set<ProdLineNode> newNodes = const {},
    Set<DirectedEdge> newEdges = const {},
    Set<ItemData> newInputs = const {},
    Set<ItemData> newOutputs = const {},
  }) : mutations = Set.unmodifiable(mutations),
       removedNodes = Set.unmodifiable(removedNodes),
       removedEdges = Set.unmodifiable(removedEdges),
       removedInputs = Set.unmodifiable(removedInputs),
       removedOutputs = Set.unmodifiable(removedOutputs),
       newNodes = Set.unmodifiable(newNodes),
       newEdges = Set.unmodifiable(newEdges),
       newInputs = Set.unmodifiable(newInputs),
       newOutputs = Set.unmodifiable(newOutputs),
       isReversed = false,
       original = null;

  GraphEvent._reverse(GraphEvent toReverse)
    : graph = toReverse.graph,
      mutations = toReverse.mutations,
      oldTopNode = toReverse.newTopNode,
      oldLeftNode = toReverse.newLeftNode,
      oldBottomNode = toReverse.newBottomNode,
      oldRightNode = toReverse.newRightNode,
      removedNodes = toReverse.newNodes,
      removedEdges = toReverse.newEdges,
      removedInputs = toReverse.newInputs,
      removedOutputs = toReverse.newOutputs,
      newTopNode = toReverse.oldTopNode,
      newLeftNode = toReverse.oldLeftNode,
      newBottomNode = toReverse.oldBottomNode,
      newRightNode = toReverse.oldRightNode,
      newNodes = toReverse.removedNodes,
      newEdges = toReverse.removedEdges,
      newInputs = toReverse.removedInputs,
      newOutputs = toReverse.removedOutputs,
      isReversed = true,
      original = toReverse;
}
