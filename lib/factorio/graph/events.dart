part of '../graph.dart';

class GraphEvent extends MutationEvent {
  final BaseGraph graph;

  final List<GraphEventType> mutations;

  final ProdLineNode? oldTopNode,
      newTopNode,
      oldLeftNode,
      newLeftNode,
      oldBottomNode,
      newBottomNode,
      oldRightNode,
      newRightNode;

  final List<ProdLineNode> newNodes, removedNodes;
  final List<DirectedEdge> newEdges, removedEdges;
  final Set<ItemData> newInputs, newOutputs, removedInputs, removedOutputs;

  final bool isReversed;
  final GraphEvent? original;
  late final GraphEvent reversed = original ?? GraphEvent._reverse(this);

  GraphEvent.newNode(BaseGraph graph, ProdLineNode newNode)
    : this._(graph, [GraphEventType.updateNodes], newNodes: [newNode]);

  GraphEvent.removeNode(BaseGraph graph, ProdLineNode removedNode)
    : this._(graph, [GraphEventType.updateNodes], removedNodes: [removedNode]);

  GraphEvent.newEdge(BaseGraph graph, DirectedEdge newEdge)
    : this._(graph, [GraphEventType.updateEdges], newEdges: [newEdge]);

  GraphEvent.removeEdge(BaseGraph graph, DirectedEdge removedEdge)
    : this._(graph, [GraphEventType.updateEdges], removedEdges: [removedEdge]);

  GraphEvent.newInput(BaseGraph graph, ItemData newInput)
    : this._(graph, [GraphEventType.updateInput], newInputs: [newInput]);

  GraphEvent.removeInput(BaseGraph graph, ItemData removedInput)
    : this._(
        graph,
        [GraphEventType.updateInput],
        removedInputs: [removedInput],
      );

  GraphEvent.newOutput(BaseGraph graph, ItemData newOutput)
    : this._(graph, [GraphEventType.updateOutput], newOutputs: [newOutput]);

  GraphEvent.removeOutput(BaseGraph graph, ItemData removedOutput)
    : this._(
        graph,
        [GraphEventType.updateOutput],
        removedOutputs: [removedOutput],
      );

  GraphEvent.newPositionalNodes(
    BaseGraph graph, {
    required ProdLineNode newTopNode,
    required ProdLineNode newLeftNode,
    required ProdLineNode newBottomNode,
    required ProdLineNode newRightNode,
  }) : this._(
         graph,
         [GraphEventType.positionalNodesUpdate],
         newTopNode: newTopNode,
         newLeftNode: newLeftNode,
         newBottomNode: newBottomNode,
         newRightNode: newRightNode,
         oldTopNode: graph.topNode,
         oldLeftNode: graph.leftNode,
         oldBottomNode: graph.bottomNode,
         oldRightNode: graph.rightNode,
       );

  GraphEvent.removePositionalNodes(BaseGraph graph)
    : this._(
        graph,
        [GraphEventType.positionalNodesUpdate],
        oldTopNode: graph.topNode,
        oldLeftNode: graph.leftNode,
        oldBottomNode: graph.bottomNode,
        oldRightNode: graph.rightNode,
      );

  factory GraphEvent.combine(List<GraphEvent> orderedEvents) {
    // Iterating through entire list for each variable isn't very efficient
    // But it is much more readable than what I was doing before
    var mutations = orderedEvents.expand((event) => event.mutations).toSet();

    var newNodes = orderedEvents.expand((event) => event.newNodes).toSet();
    var removedNodes = orderedEvents
        .expand((event) => event.removedNodes)
        .toSet();
    var newEdges = orderedEvents.expand((event) => event.newEdges).toSet();
    var removedEdges = orderedEvents
        .expand((event) => event.removedEdges)
        .toSet();
    _removedWhereBothContain(newNodes, removedNodes);
    _removedWhereBothContain(newEdges, removedEdges);

    var newInputs = orderedEvents.expand((event) => event.newInputs).toSet();
    var removedInputs = orderedEvents
        .expand((event) => event.removedInputs)
        .toSet();
    var newOutputs = orderedEvents.expand((event) => event.newOutputs).toSet();
    var removedOutputs = orderedEvents
        .expand((event) => event.removedOutputs)
        .toSet();
    _removedWhereBothContain(newInputs, removedInputs);
    _removedWhereBothContain(newOutputs, removedOutputs);

    ProdLineNode? oldTop,
        newTop,
        oldLeft,
        newLeft,
        oldBottom,
        newBottom,
        oldRight,
        newRight;

    var oldPosition = orderedEvents
        .where(
          (event) =>
              event.mutations.contains(GraphEventType.positionalNodesUpdate),
        )
        .firstOrNull;
    var newPosition = orderedEvents
        .where(
          (event) =>
              event.mutations.contains(GraphEventType.positionalNodesUpdate),
        )
        .lastOrNull;

    if (oldPosition != null && newPosition != null) {
      newTop = newPosition.newTopNode;
      newLeft = newPosition.newLeftNode;
      newBottom = newPosition.newBottomNode;
      newRight = newPosition.newRightNode;
      oldTop = oldPosition.oldTopNode;
      oldLeft = oldPosition.oldLeftNode;
      oldBottom = oldPosition.oldBottomNode;
      oldRight = oldPosition.oldRightNode;
    }

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
    Iterable<GraphEventType> mutations, {
    this.newTopNode,
    this.newLeftNode,
    this.newBottomNode,
    this.newRightNode,
    Iterable<ProdLineNode> newNodes = const [],
    Iterable<DirectedEdge> newEdges = const [],
    Iterable<ItemData> newInputs = const [],
    Iterable<ItemData> newOutputs = const [],
    this.oldTopNode,
    this.oldLeftNode,
    this.oldBottomNode,
    this.oldRightNode,
    Iterable<ProdLineNode> removedNodes = const [],
    Iterable<DirectedEdge> removedEdges = const [],
    Iterable<ItemData> removedInputs = const [],
    Iterable<ItemData> removedOutputs = const [],
  }) : mutations = List.unmodifiable(mutations),
       newNodes = List.unmodifiable(newNodes),
       newEdges = List.unmodifiable(newEdges),
       newInputs = Set.unmodifiable(newInputs),
       newOutputs = Set.unmodifiable(newOutputs),
       removedNodes = List.unmodifiable(removedNodes),
       removedEdges = List.unmodifiable(removedEdges),
       removedInputs = Set.unmodifiable(removedInputs),
       removedOutputs = Set.unmodifiable(removedOutputs),
       isReversed = false,
       original = null;

  GraphEvent._reverse(GraphEvent toReverse)
    : graph = toReverse.graph,
      mutations = toReverse.mutations,
      newTopNode = toReverse.oldTopNode,
      newLeftNode = toReverse.oldLeftNode,
      newBottomNode = toReverse.oldBottomNode,
      newRightNode = toReverse.oldRightNode,
      newNodes = toReverse.removedNodes,
      newEdges = toReverse.removedEdges,
      newInputs = toReverse.removedInputs,
      newOutputs = toReverse.removedOutputs,
      oldTopNode = toReverse.newTopNode,
      oldLeftNode = toReverse.newLeftNode,
      oldBottomNode = toReverse.newBottomNode,
      oldRightNode = toReverse.newRightNode,
      removedNodes = toReverse.newNodes,
      removedEdges = toReverse.newEdges,
      removedInputs = toReverse.newInputs,
      removedOutputs = toReverse.newOutputs,
      isReversed = true,
      original = toReverse;
}

class NodeEvent extends MutationEvent {
  final ProdLineNode node;

  final List<NodeEventType> mutations;

  final Offset? oldTopLeft, oldBottomRight, newTopLeft, newBottomRight;
  final ItemIo? oldRequirements, newRequirements;
  final NodeType? oldNodeType, newNodeType;
  final ProductionLine? oldProductionLine, newProductionLine;
  final List<DirectedEdge> newChildOf,
      newParentOf,
      removedChildOf,
      removedParentOf;

  final bool isReversed;
  final NodeEvent? original;
  late final NodeEvent reversed = original ?? NodeEvent._reverse(this);

  NodeEvent.updatePosition(
    ProdLineNode node,
    Offset newTopLeft,
    Offset newBottomRight,
  ) : this._(
        node,
        [NodeEventType.newPosition],
        newTopLeft: newTopLeft,
        newBottomRight: newBottomRight,
        oldTopLeft: node.topLeft,
        oldBottomRight: node.bottomRight,
      );

  NodeEvent.newRequirements(ProdLineNode node, ItemIo newRequirements)
    : this._(
        node,
        [NodeEventType.newRequirements],
        newRequirements: newRequirements,
        oldRequirements: node.requirements,
      );

  NodeEvent.clearRequirements(ProdLineNode node)
    : this._(node, [
        NodeEventType.newRequirements,
      ], oldRequirements: node.requirements);

  NodeEvent.newType(ProdLineNode node, NodeType newType)
    : this._(
        node,
        [NodeEventType.newNodeType],
        newNodeType: newType,
        oldNodeType: node.nodeType,
      );

  NodeEvent.newProductionLine(
    ProdLineNode node,
    ProductionLine newProductionLine,
  ) : this._(
        node,
        [NodeEventType.newProductionLine],
        newProductionLine: newProductionLine,
        oldProductionLine: node._line,
      );

  NodeEvent.newChildEdge(ProdLineNode node, DirectedEdge newChildEdge)
    : this._(node, [NodeEventType.parentOfUpdate], newParentOf: [newChildEdge]);

  NodeEvent.newParentEdge(ProdLineNode node, DirectedEdge newParentEdge)
    : this._(node, [NodeEventType.childOfUpdate], newChildOf: [newParentEdge]);

  NodeEvent.removeChildEdge(ProdLineNode node, DirectedEdge removedChildEdge)
    : this._(
        node,
        [NodeEventType.parentOfUpdate],
        removedParentOf: [removedChildEdge],
      );

  NodeEvent.removeParentEdge(ProdLineNode node, DirectedEdge removedParentEdge)
    : this._(
        node,
        [NodeEventType.childOfUpdate],
        removedChildOf: [removedParentEdge],
      );

  factory NodeEvent.combine(List<NodeEvent> orderedEvents) {
    // Iterating through entire list for each variable isn't very efficient
    // But it is much more readable than what I was doing before
    var mutations = orderedEvents.expand((event) => event.mutations).toSet();
    if (mutations.containsAll(const [
      NodeEventType.addedToGraph,
      NodeEventType.removedFromGraph,
    ])) {
      mutations.removeAll(const [
        NodeEventType.addedToGraph,
        NodeEventType.removedFromGraph,
      ]);
    }

    var newParentOf = orderedEvents
        .expand((event) => event.newParentOf)
        .toSet();
    var removedParentOf = orderedEvents
        .expand((event) => event.removedParentOf)
        .toSet();
    var newChildOf = orderedEvents.expand((event) => event.newChildOf).toSet();
    var removedChildOf = orderedEvents
        .expand((event) => event.removedChildOf)
        .toSet();
    _removedWhereBothContain(newParentOf, removedParentOf);
    _removedWhereBothContain(newChildOf, removedChildOf);

    ItemIo? oldRequirements, newRequirements;
    var oldRequirementsEvent = orderedEvents
        .where(
          (event) => event.mutations.contains(NodeEventType.newRequirements),
        )
        .firstOrNull;
    var newRequirementsEvent = orderedEvents
        .where(
          (event) => event.mutations.contains(NodeEventType.newRequirements),
        )
        .lastOrNull;

    if (oldRequirementsEvent != null && newRequirementsEvent != null) {
      oldRequirements = oldRequirementsEvent.oldRequirements;
      newRequirements = newRequirementsEvent.newRequirements;
    }

    NodeType? newNodeType, oldNodeType;
    var oldNodeTypeEvent = orderedEvents
        .where((event) => event.mutations.contains(NodeEventType.newNodeType))
        .firstOrNull;
    var newNodeTypeEvent = orderedEvents
        .where((event) => event.mutations.contains(NodeEventType.newNodeType))
        .lastOrNull;

    if (oldNodeTypeEvent != null && newNodeTypeEvent != null) {
      oldNodeType = oldNodeTypeEvent.oldNodeType;
      newNodeType = newNodeTypeEvent.newNodeType;
    }

    ProductionLine? newProdLine, oldProdLine;
    var oldProdLineEvent = orderedEvents
        .where((event) => event.mutations.contains(NodeEventType.newNodeType))
        .firstOrNull;
    var newProdLineEvent = orderedEvents
        .where((event) => event.mutations.contains(NodeEventType.newNodeType))
        .lastOrNull;

    if (oldProdLineEvent != null && newProdLineEvent != null) {
      oldProdLine = oldProdLineEvent.oldProductionLine;
      newProdLine = newProdLineEvent.newProductionLine;
    }

    Offset? newTopLeft, oldTopLeft, newBottomRight, oldBottomRight;
    var oldPositionEvent = orderedEvents
        .where((event) => event.mutations.contains(NodeEventType.newPosition))
        .firstOrNull;
    var newPositionEvent = orderedEvents
        .where((event) => event.mutations.contains(NodeEventType.newPosition))
        .lastOrNull;

    if (oldPositionEvent != null && newPositionEvent != null) {
      oldTopLeft = oldPositionEvent.oldTopLeft;
      oldBottomRight = oldPositionEvent.oldBottomRight;
      newTopLeft = newPositionEvent.newTopLeft;
      newBottomRight = newPositionEvent.newBottomRight;
    }

    return NodeEvent._(
      orderedEvents.first.node,
      mutations,
      newTopLeft: newTopLeft,
      newBottomRight: newBottomRight,
      newRequirements: newRequirements,
      newNodeType: newNodeType,
      newProductionLine: newProdLine,
      newParentOf: newParentOf,
      newChildOf: newChildOf,
      oldTopLeft: oldTopLeft,
      oldBottomRight: oldBottomRight,
      oldRequirements: oldRequirements,
      oldNodeType: oldNodeType,
      oldProductionLine: oldProdLine,
      removedParentOf: removedParentOf,
      removedChildOf: removedChildOf,
    );
  }

  NodeEvent._(
    this.node,
    Iterable<NodeEventType> mutations, {
    this.newTopLeft,
    this.newBottomRight,
    ItemIo? newRequirements,
    this.newNodeType,
    this.newProductionLine,
    Iterable<DirectedEdge> newParentOf = const [],
    Iterable<DirectedEdge> newChildOf = const [],
    this.oldTopLeft,
    this.oldBottomRight,
    ItemIo? oldRequirements,
    this.oldNodeType,
    this.oldProductionLine,
    Iterable<DirectedEdge> removedParentOf = const [],
    Iterable<DirectedEdge> removedChildOf = const [],
  }) : mutations = List.unmodifiable(mutations),
       newRequirements = newRequirements != null
           ? Map.unmodifiable(newRequirements)
           : null,
       newParentOf = List.unmodifiable(newParentOf),
       newChildOf = List.unmodifiable(newChildOf),
       oldRequirements = oldRequirements != null
           ? Map.unmodifiable(oldRequirements)
           : null,
       removedParentOf = List.unmodifiable(removedParentOf),
       removedChildOf = List.unmodifiable(removedChildOf),
       isReversed = false,
       original = null;

  NodeEvent._reverse(NodeEvent toReverse)
    : node = toReverse.node,
      mutations = List.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldTopLeft = toReverse.newTopLeft,
      oldBottomRight = toReverse.newBottomRight,
      newTopLeft = toReverse.oldTopLeft,
      newBottomRight = toReverse.oldBottomRight,
      oldRequirements = toReverse.newRequirements,
      newRequirements = toReverse.oldRequirements,
      oldNodeType = toReverse.newNodeType,
      newNodeType = toReverse.oldNodeType,
      oldProductionLine = toReverse.newProductionLine,
      newProductionLine = toReverse.oldProductionLine,
      removedChildOf = toReverse.newChildOf,
      newChildOf = toReverse.removedChildOf,
      removedParentOf = toReverse.newParentOf,
      newParentOf = toReverse.removedParentOf,
      isReversed = true,
      original = toReverse;
}

class EdgeEvent extends MutationEvent {
  final DirectedEdge edge;

  final List<EdgeEventType> mutations;

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

  EdgeEvent.newAmount(DirectedEdge edge, double newAmount)
    : this._(
        edge,
        [EdgeEventType.newAmount],
        newAmount: newAmount,
        oldAmount: edge.amount,
      );

  EdgeEvent.clearAmount(DirectedEdge edge)
    : this._(edge, [EdgeEventType.newAmount], oldAmount: edge.amount);

  EdgeEvent.updateLines(
    DirectedEdge edge,
    List<Offset> newLines, {
    required Side newParentConnectionSide,
    required Side newChildConnectionSide,
  }) : this.updateLineType(
         edge,
         newLines,
         edge.lineType,
         newParentConnectionSide: newParentConnectionSide,
         newChildConnectionSide: newChildConnectionSide,
       );

  EdgeEvent.updateLineType(
    DirectedEdge edge,
    List<Offset> newLines,
    LineType newLineType, {
    required Side newParentConnectionSide,
    required Side newChildConnectionSide,
  }) : this._(
         edge,
         [EdgeEventType.newLines],
         newLines: newLines,
         newLineType: newLineType,
         newParentConnection: newParentConnectionSide,
         newChildConnection: newChildConnectionSide,
         oldLines: edge.lines,
         oldLineType: edge.lineType,
         oldParentConnection: edge.parentConnectionSide,
         oldChildConnection: edge.childConnectionSide,
       );

  factory EdgeEvent.combine(List<EdgeEvent> orderedEvents) {
    // Iterating through entire list for each variable isn't very efficient
    // But it is much more readable than what I was doing before
    var mutations = orderedEvents.expand((event) => event.mutations).toSet();
    if (mutations.containsAll(const [
      EdgeEventType.addedToGraph,
      EdgeEventType.removedFromGraph,
    ])) {
      mutations.removeAll(const [
        EdgeEventType.addedToGraph,
        EdgeEventType.removedFromGraph,
      ]);
    }

    double? oldAmount, newAmount;
    var oldAmountEvent = orderedEvents
        .where((event) => event.mutations.contains(EdgeEventType.newAmount))
        .firstOrNull;
    var newAmountEvent = orderedEvents
        .where((event) => event.mutations.contains(EdgeEventType.newAmount))
        .lastOrNull;

    if (oldAmountEvent != null && newAmountEvent != null) {
      oldAmount = oldAmountEvent.oldAmount;
      newAmount = newAmountEvent.newAmount;
    }

    LineType? oldLineType, newLineType;
    Side? oldParentConnection,
        oldChildConnection,
        newParentConnection,
        newChildConnection;
    List<Offset>? oldLines, newLines;
    var oldLinesEvent = orderedEvents
        .where((event) => event.mutations.contains(EdgeEventType.newLines))
        .firstOrNull;
    var newLinestEvent = orderedEvents
        .where((event) => event.mutations.contains(EdgeEventType.newLines))
        .lastOrNull;

    if (oldLinesEvent != null && newLinestEvent != null) {
      oldLineType = oldLinesEvent.oldLineType;
      oldParentConnection = oldLinesEvent.oldParentConnection;
      oldChildConnection = oldLinesEvent.oldChildConnection;
      oldLines = oldLinesEvent.oldLines;
      newLineType = newLinestEvent.newLineType;
      newParentConnection = newLinestEvent.newParentConnection;
      newChildConnection = newLinestEvent.newChildConnection;
      newLines = newLinestEvent.newLines;
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
    Iterable<EdgeEventType> mutations, {
    this.newAmount,
    this.newLineType,
    this.newParentConnection,
    this.newChildConnection,
    List<Offset>? newLines,
    this.oldAmount,
    this.oldLineType,
    this.oldParentConnection,
    this.oldChildConnection,
    this.oldLines, // This list should already be unmodifiable
  }) : mutations = List.unmodifiable(mutations),
       newLines = newLines != null ? List.unmodifiable(newLines) : null,
       isReversed = false,
       original = null;

  EdgeEvent._reverse(EdgeEvent toReverse)
    : edge = toReverse.edge,
      mutations = List.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      newAmount = toReverse.oldAmount,
      newLineType = toReverse.oldLineType,
      newParentConnection = toReverse.oldParentConnection,
      newChildConnection = toReverse.oldChildConnection,
      newLines = toReverse.oldLines,
      oldAmount = toReverse.newAmount,
      oldLineType = toReverse.newLineType,
      oldParentConnection = toReverse.newParentConnection,
      oldChildConnection = toReverse.newChildConnection,
      oldLines = toReverse.newLines,
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
}

void _removedWhereBothContain(Set set1, Set set2) {
  for (var item in List.from(set1)) {
    if (set2.contains(item)) {
      set1.remove(item);
      set2.remove(item);
    }
  }
}
