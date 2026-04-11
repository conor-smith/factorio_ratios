part of '../graph.dart';

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

class NodeEvent extends MutationEvent {
  final ProdLineNode node;

  final Set<NodeEventType> mutations;

  final Rect? oldRect, newRect;
  final ItemIo? oldRequirements, newRequirements;
  final NodeType? oldNodeType, newNodeType;
  final ProductionLine? oldProductionLine, newProductionLine;
  final Set<DirectedEdge> newChildOf,
      newParentOf,
      removedChildOf,
      removedParentOf;

  final bool isReversed;
  final NodeEvent? original;
  late final NodeEvent reversed = original ?? NodeEvent._reverse(this);

  NodeEvent.addToGraph(ProdLineNode node)
    : this._(node, {NodeEventType.addedToGraph});

  NodeEvent.removeFromGraph(ProdLineNode node)
    : this._(node, {NodeEventType.removedFromGraph});

  NodeEvent.updatePosition(ProdLineNode node, Rect newRect)
    : this._(
        node,
        {NodeEventType.newPosition},
        oldRect: node._internalRect,
        newRect: newRect,
      );

  NodeEvent.newRequirements(ProdLineNode node, ItemIo newRequirements)
    : this._(
        node,
        {NodeEventType.newRequirements},
        oldRequirements: node.requirements,
        newRequirements: newRequirements,
      );

  NodeEvent.clearRequirements(ProdLineNode node)
    : this._(node, {
        NodeEventType.newRequirements,
      }, oldRequirements: node.requirements);

  NodeEvent.newType(ProdLineNode node, NodeType newType)
    : this._(
        node,
        {NodeEventType.newNodeType},
        oldNodeType: node.nodeType,
        newNodeType: newType,
      );

  NodeEvent.newProductionLine(
    ProdLineNode node,
    ProductionLine newProductionLine,
  ) : this._(
        node,
        {NodeEventType.newProductionLine},
        oldProductionLine: node._line,
        newProductionLine: newProductionLine,
      );

  NodeEvent.newChildEdge(ProdLineNode node, DirectedEdge newChildEdge)
    : this._(node, {NodeEventType.parentOfUpdate}, newParentOf: {newChildEdge});

  NodeEvent.newParentEdge(ProdLineNode node, DirectedEdge newParentEdge)
    : this._(node, {NodeEventType.childOfUpdate}, newChildOf: {newParentEdge});

  NodeEvent.removeChildEdge(ProdLineNode node, DirectedEdge removedChildEdge)
    : this._(
        node,
        {NodeEventType.parentOfUpdate},
        removedParentOf: {removedChildEdge},
      );

  NodeEvent.removeParentEdge(ProdLineNode node, DirectedEdge removedParentEdge)
    : this._(
        node,
        {NodeEventType.childOfUpdate},
        removedChildOf: {removedParentEdge},
      );

  factory NodeEvent.combine(List<NodeEvent> orderedEvents) {
    Set<NodeEventType> mutations = {};

    Set<DirectedEdge> newParentOf = {};
    Set<DirectedEdge> removedParentOf = {};
    Set<DirectedEdge> newChildOf = {};
    Set<DirectedEdge> removedChildOf = {};

    NodeEvent? oldPositionEvent, newPositionEvent;
    Rect? oldRect, newRect;

    NodeEvent? oldNodeTypeEvent, newNodeTypeEvent;
    NodeType? oldNodeType, newNodeType;

    NodeEvent? oldRequirementsEvent, newRequirementsEvent;
    ItemIo? oldRequirements, newRequirements;

    NodeEvent? oldProdLineEvent, newProdLineEvent;
    ProductionLine? oldProdLine, newProdLine;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case NodeEventType.newPosition:
            oldPositionEvent ??= event;
            newPositionEvent = event;

          case NodeEventType.newRequirements:
            oldRequirementsEvent ??= event;
            newRequirementsEvent = event;

          case NodeEventType.newNodeType:
            oldNodeTypeEvent ??= event;
            newNodeTypeEvent = event;

          case NodeEventType.newProductionLine:
            oldProdLineEvent ??= event;
            newProdLineEvent = event;

          case NodeEventType.parentOfUpdate:
            newParentOf.addAll(event.newParentOf);
            removedParentOf.addAll(event.removedParentOf);

          case NodeEventType.childOfUpdate:
            newChildOf.addAll(event.newChildOf);
            removedChildOf.addAll(event.removedChildOf);

          case NodeEventType.addedToGraph:
          case NodeEventType.removedFromGraph:
            break;
        }
      }
    }

    if (oldPositionEvent != null) {
      oldRect = oldPositionEvent.oldRect;
      newRect = newPositionEvent!.newRect;
    }

    if (oldRequirementsEvent != null) {
      oldRequirements = oldRequirementsEvent.oldRequirements;
      newRequirements = newRequirementsEvent!.newRequirements;
    }

    if (oldNodeTypeEvent != null) {
      oldNodeType = oldNodeTypeEvent.oldNodeType;
      newNodeType = newNodeTypeEvent!.newNodeType;
    }

    if (oldProdLineEvent != null) {
      oldProdLine = oldProdLineEvent.oldProductionLine;
      newProdLine = newProdLineEvent!.newProductionLine;
    }

    _removedWhereBothContain(newParentOf, removedParentOf);
    _removedWhereBothContain(newChildOf, removedChildOf);

    if (mutations.containsAll(NodeEventType.creationEvents)) {
      mutations.removeAll(NodeEventType.creationEvents);
    }

    return NodeEvent._(
      orderedEvents.first.node,
      mutations,
      oldRect: oldRect,
      oldRequirements: oldRequirements,
      oldNodeType: oldNodeType,
      oldProductionLine: oldProdLine,
      removedParentOf: removedParentOf,
      removedChildOf: removedChildOf,
      newRect: newRect,
      newRequirements: newRequirements,
      newNodeType: newNodeType,
      newProductionLine: newProdLine,
      newParentOf: newParentOf,
      newChildOf: newChildOf,
    );
  }

  NodeEvent._(
    this.node,
    Set<NodeEventType> mutations, {
    ItemIo? oldRequirements,
    this.oldRect,
    this.oldNodeType,
    this.oldProductionLine,
    Set<DirectedEdge> removedParentOf = const {},
    Set<DirectedEdge> removedChildOf = const {},
    ItemIo? newRequirements,
    this.newRect,
    this.newNodeType,
    this.newProductionLine,
    Set<DirectedEdge> newParentOf = const {},
    Set<DirectedEdge> newChildOf = const {},
  }) : mutations = Set.unmodifiable(mutations),
       newRequirements = newRequirements != null
           ? Map.unmodifiable(newRequirements)
           : null,
       newParentOf = Set.unmodifiable(newParentOf),
       newChildOf = Set.unmodifiable(newChildOf),
       oldRequirements = oldRequirements != null
           ? Map.unmodifiable(oldRequirements)
           : null,
       removedParentOf = Set.unmodifiable(removedParentOf),
       removedChildOf = Set.unmodifiable(removedChildOf),
       isReversed = false,
       original = null;

  NodeEvent._reverse(NodeEvent toReverse)
    : node = toReverse.node,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldRect = toReverse.newRect,
      oldRequirements = toReverse.newRequirements,
      oldNodeType = toReverse.newNodeType,
      oldProductionLine = toReverse.newProductionLine,
      removedParentOf = toReverse.newParentOf,
      removedChildOf = toReverse.newChildOf,
      newRect = toReverse.oldRect,
      newRequirements = toReverse.oldRequirements,
      newNodeType = toReverse.oldNodeType,
      newProductionLine = toReverse.oldProductionLine,
      newParentOf = toReverse.removedParentOf,
      newChildOf = toReverse.removedChildOf,
      isReversed = true,
      original = toReverse;
}

class EdgeEvent extends MutationEvent {
  final DirectedEdge edge;

  final Set<EdgeEventType> mutations;

  final double? oldAmount, newAmount;

  final LineType? oldLineType, newLineType;
  final Side? oldParentConnection,
      oldChildConnection,
      newParentConnection,
      newChildConnection;
  final List<Offset>? oldLines, newLines;

  final bool isReversed;
  final EdgeEvent? original;
  late final EdgeEvent reversed = original ?? EdgeEvent._reverse(this);

  EdgeEvent.addToGraph(DirectedEdge edge)
    : this._(edge, {EdgeEventType.addedToGraph});

  EdgeEvent.removeFromGraph(DirectedEdge edge)
    : this._(edge, {EdgeEventType.removedFromGraph});

  EdgeEvent.newAmount(DirectedEdge edge, double newAmount)
    : this._(
        edge,
        {EdgeEventType.newAmount},
        oldAmount: edge.amount,
        newAmount: newAmount,
      );

  EdgeEvent.clearAmount(DirectedEdge edge)
    : this._(edge, {EdgeEventType.newAmount}, oldAmount: edge.amount);

  EdgeEvent.updateLines(
    DirectedEdge edge,
    List<Offset> newLines,
    Side newParentConnectionSide,
    Side newChildConnectionSide,
  ) : this.updateLineType(
        edge,
        newLines,
        edge.lineType,
        newParentConnectionSide,
        newChildConnectionSide,
      );

  EdgeEvent.updateLineType(
    DirectedEdge edge,
    List<Offset> newLines,
    LineType newLineType,
    Side newParentConnectionSide,
    Side newChildConnectionSide,
  ) : this._(
        edge,
        {EdgeEventType.newLines},
        oldLines: edge.lines,
        oldLineType: edge.lineType,
        oldParentConnection: edge.parentConnection,
        oldChildConnection: edge.childConnection,
        newLines: newLines,
        newLineType: newLineType,
        newParentConnection: newParentConnectionSide,
        newChildConnection: newChildConnectionSide,
      );

  factory EdgeEvent.combine(List<EdgeEvent> orderedEvents) {
    Set<EdgeEventType> mutations = {};

    EdgeEvent? oldAmountEvent, newAmountEvent;
    double? oldAmount, newAmount;

    EdgeEvent? oldLinesEvent, newLinesEvent;
    Side? oldParentConnection,
        oldChildConnection,
        newParentConnection,
        newChildConnection;
    LineType? oldLineType, newLineType;
    List<Offset>? oldLines, newLines;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case EdgeEventType.newAmount:
            oldAmountEvent ??= event;
            newAmountEvent = event;

          case EdgeEventType.newLines:
            oldLinesEvent ??= event;
            newLinesEvent = event;

          case EdgeEventType.addedToGraph:
          case EdgeEventType.removedFromGraph:
            break;
        }
      }
    }

    if (mutations.containsAll(EdgeEventType.creationEvents)) {
      mutations.removeAll(EdgeEventType.creationEvents);
    }

    if (oldAmountEvent != null) {
      oldAmount = oldAmountEvent.oldAmount;
      newAmount = newAmountEvent!.newAmount;
    }

    if (oldLinesEvent != null) {
      oldParentConnection = oldLinesEvent.oldParentConnection;
      oldChildConnection = oldLinesEvent.oldChildConnection;
      oldLineType = oldLinesEvent.oldLineType;
      oldLines = oldLinesEvent.oldLines;
      newParentConnection = newLinesEvent!.newParentConnection;
      newChildConnection = newLinesEvent.newChildConnection;
      newLineType = newLinesEvent.newLineType;
      newLines = newLinesEvent.newLines;
    }

    return EdgeEvent._(
      orderedEvents.first.edge,
      mutations,
      oldAmount: oldAmount,
      oldLineType: oldLineType,
      oldParentConnection: oldParentConnection,
      oldChildConnection: oldChildConnection,
      oldLines: oldLines,
      newAmount: newAmount,
      newLineType: newLineType,
      newParentConnection: newParentConnection,
      newChildConnection: newChildConnection,
      newLines: newLines,
    );
  }

  EdgeEvent._(
    this.edge,
    Set<EdgeEventType> mutations, {
    this.oldAmount,
    this.oldLineType,
    this.oldParentConnection,
    this.oldChildConnection,
    this.oldLines, // This list should already be unmodifiable
    this.newAmount,
    this.newLineType,
    this.newParentConnection,
    this.newChildConnection,
    List<Offset>? newLines,
  }) : mutations = Set.unmodifiable(mutations),
       newLines = newLines != null ? List.unmodifiable(newLines) : null,
       isReversed = false,
       original = null;

  EdgeEvent._reverse(EdgeEvent toReverse)
    : edge = toReverse.edge,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldAmount = toReverse.newAmount,
      oldLineType = toReverse.newLineType,
      oldParentConnection = toReverse.newParentConnection,
      oldChildConnection = toReverse.newChildConnection,
      oldLines = toReverse.newLines,
      newAmount = toReverse.oldAmount,
      newLineType = toReverse.oldLineType,
      newParentConnection = toReverse.oldParentConnection,
      newChildConnection = toReverse.oldChildConnection,
      newLines = toReverse.oldLines,
      isReversed = true,
      original = toReverse;
}

enum GraphEventType {
  positionalNodesUpdate,
  updateNodes,
  updateEdges,
  updateInput,
  updateOutput,
}

enum NodeEventType {
  newPosition,
  newRequirements,
  newNodeType,
  newProductionLine,
  parentOfUpdate,
  childOfUpdate,
  addedToGraph,
  removedFromGraph;

  NodeEventType get reverse => switch (this) {
    newPosition => newPosition,
    newRequirements => newRequirements,
    newNodeType => newNodeType,
    newProductionLine => newProductionLine,
    parentOfUpdate => parentOfUpdate,
    childOfUpdate => childOfUpdate,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<NodeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}

enum EdgeEventType {
  newAmount,
  newLines,
  addedToGraph,
  removedFromGraph;

  EdgeEventType get reverse => switch (this) {
    newAmount => newAmount,
    newLines => newLines,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<EdgeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}

void _removedWhereBothContain(Set set1, Set set2) {
  for (var item in List.from(set1)) {
    if (set2.contains(item)) {
      set1.remove(item);
      set2.remove(item);
    }
  }
}
