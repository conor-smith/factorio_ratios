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

  GraphEvent._(
    this.graph,
    List<GraphEventType> mutations, {
    this.newTopNode,
    this.newLeftNode,
    this.newBottomNode,
    this.newRightNode,
    List<ProdLineNode> newNodes = const [],
    List<ProdLineNode> removedNodes = const [],
    List<DirectedEdge> newEdges = const [],
    List<DirectedEdge> removedEdges = const [],
    Set<ItemData> newInputs = const {},
    Set<ItemData> newOutputs = const {},
    Set<ItemData> removedInputs = const {},
    Set<ItemData> removedOutputs = const {},
  }) : mutations = List.unmodifiable(mutations),
       oldTopNode = graph._topNode,
       oldLeftNode = graph._leftNode,
       oldBottomNode = graph._bottomNode,
       oldRightNode = graph._rightNode,
       newNodes = List.unmodifiable(newNodes),
       removedNodes = List.unmodifiable(removedNodes),
       newEdges = List.unmodifiable(newEdges),
       removedEdges = List.unmodifiable(removedEdges),
       newInputs = Set.unmodifiable(newInputs),
       newOutputs = Set.unmodifiable(newOutputs),
       removedInputs = Set.unmodifiable(removedInputs),
       removedOutputs = Set.unmodifiable(removedOutputs),
       isReversed = false,
       original = null {
    for (var mutation in mutations) {
      switch (mutation) {
        case GraphEventType.updateNodes:
          var duplicate = _containsAny(newNodes, removedNodes);
          if (duplicate != null) {
            throw MutationException('Node "$duplicate" both added and removed');
          }
        case GraphEventType.updateEdges:
          var duplicate = _containsAny(newEdges, removedEdges);
          if (duplicate != null) {
            throw MutationException('Edge "$duplicate" both added and removed');
          }
        case GraphEventType.updateInput:
          var duplicate = _containsAny(newInputs, removedInputs);
          if (duplicate != null) {
            throw MutationException(
              'Input item "$duplicate" both added and removed',
            );
          }
        case GraphEventType.updateOutput:
          var duplicate = _containsAny(newOutputs, removedOutputs);
          if (duplicate != null) {
            throw MutationException(
              'Output item "$duplicate" both added and removed',
            );
          }
        case GraphEventType.positionalNodesUpdate:
          break;
      }
    }
  }

  GraphEvent._reverse(GraphEvent toReverse)
    : graph = toReverse.graph,
      mutations = toReverse.mutations,
      oldTopNode = toReverse.newTopNode,
      oldLeftNode = toReverse.newLeftNode,
      oldBottomNode = toReverse.newBottomNode,
      oldRightNode = toReverse.newRightNode,
      newTopNode = toReverse.oldTopNode,
      newLeftNode = toReverse.oldLeftNode,
      newBottomNode = toReverse.oldBottomNode,
      newRightNode = toReverse.oldRightNode,
      newNodes = toReverse.removedNodes,
      newEdges = toReverse.removedEdges,
      newInputs = toReverse.removedInputs,
      newOutputs = toReverse.removedOutputs,
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

  NodeEvent._(
    this.node,
    List<NodeEventType> mutations, {
    this.newTopLeft,
    this.newBottomRight,
    ItemIo? newRequirement,
    this.newNodeType,
    this.newProductionLine,
    List<DirectedEdge> newChildOf = const [],
    List<DirectedEdge> newParentOf = const [],
    List<DirectedEdge> removedChildOf = const [],
    List<DirectedEdge> removedParentOf = const [],
  }) : mutations = List.unmodifiable(mutations),
       oldTopLeft = node.topLeft,
       oldBottomRight = node.bottomRight,
       oldRequirements = node.requirements != null
           ? Map.unmodifiable(node.requirements!)
           : null,
       oldNodeType = node.nodeType,
       oldProductionLine = node._line,
       newRequirements = newRequirement != null
           ? Map.unmodifiable(newRequirement)
           : null,
       newChildOf = List.unmodifiable(newChildOf),
       newParentOf = List.unmodifiable(newParentOf),
       removedChildOf = List.unmodifiable(removedChildOf),
       removedParentOf = List.unmodifiable(removedParentOf),
       isReversed = false,
       original = null {
    for (var mutation in mutations) {
      switch (mutation) {
        case NodeEventType.newPosition:
          if (newTopLeft == null || newBottomRight == null) {
            throw const MutationException('Must specify all offsets');
          }

        case NodeEventType.newNodeType:
          if (oldNodeType == null || newNodeType == null) {
            throw const MutationException('Must specify node type update');
          }

        case NodeEventType.newProductionLine:
          if (oldProductionLine == null || newProductionLine == null) {
            throw const MutationException(
              'Must specify production line update',
            );
          }

        case NodeEventType.parentOfUpdate:
          var duplicate = _containsAny(newParentOf, removedParentOf);
          if (duplicate != null) {
            throw MutationException(
              'Edge "$duplicate" both added and removed to parentOf',
            );
          }

        case NodeEventType.childrenOfUpdate:
          var duplicate = _containsAny(newChildOf, removedChildOf);
          if (duplicate != null) {
            throw MutationException(
              'Edge "$duplicate" both added and removed to parentOf',
            );
          }

        case NodeEventType.addedToGraph:
        case NodeEventType.removedFromGraph:
          if (mutations.contains(mutation.reverse)) {
            throw const MutationException(
              'Node cannot be added to and removed from graph in same event',
            );
          }
        case NodeEventType.requirementsUpdate:
          break;
      }
    }
  }

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
  final Side? oldParentConnection,
      oldChildConnection,
      newParentConnection,
      newChildConnection;
  final List<Offset>? oldLines, newLines;

  final bool isReversed;
  final EdgeEvent? original;
  late final EdgeEvent reversed = original ?? EdgeEvent._reverse(this);

  EdgeEvent._(
    this.edge,
    List<EdgeEventType> mutations, {
    this.newAmount,
    this.newParentConnection,
    this.newChildConnection,
    List<Offset>? newLines,
  }) : mutations = List.unmodifiable(mutations),
       oldAmount = edge._amount,
       oldParentConnection = edge._parentConnectionSide,
       oldChildConnection = edge._childConnectionSide,
       oldLines = edge._lines,
       newLines = newLines != null ? List.unmodifiable(newLines) : null,
       isReversed = false,
       original = null {
    for (var mutation in mutations) {
      switch (mutation) {
        case EdgeEventType.newLines:
          if (newLines == null ||
              newChildConnection == null ||
              newParentConnection == null) {
            throw const MutationException('Must specify lines update');
          }

        case EdgeEventType.addedToGraph:
        case EdgeEventType.removedFromGraph:
          if (mutations.contains(mutation.reverse)) {
            throw const MutationException(
              'Edge cannot be added to and removed from graph in same event',
            );
          }

        case EdgeEventType.newAmount:
          break;
      }
    }
  }

  EdgeEvent._reverse(EdgeEvent toReverse)
    : edge = toReverse.edge,
      mutations = List.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldAmount = toReverse.newAmount,
      newAmount = toReverse.oldAmount,
      oldParentConnection = toReverse.newParentConnection,
      oldChildConnection = toReverse.newChildConnection,
      oldLines = toReverse.newLines,
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
  requirementsUpdate,
  newNodeType,
  newProductionLine,
  parentOfUpdate,
  childrenOfUpdate,
  addedToGraph,
  removedFromGraph;

  NodeEventType get reverse => switch (this) {
    newPosition => newPosition,
    requirementsUpdate => requirementsUpdate,
    newNodeType => newNodeType,
    newProductionLine => newProductionLine,
    parentOfUpdate => parentOfUpdate,
    childrenOfUpdate => childrenOfUpdate,
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

T? _containsAny<T>(Iterable<T> it1, Iterable<T> it2) {
  for (var item in it1) {
    if (it2.contains(item)) {
      return item;
    }
  }
}
