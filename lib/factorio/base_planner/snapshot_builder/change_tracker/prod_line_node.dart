part of '../snapshot_builder.dart';

class ProdLineNodeChangeTracker
    extends
        NodeChangeTracker<
          ProdLineNode,
          ProdLineNodeStateImpl,
          NodeDependencies,
          ProdLineNodeStateBuilder
        > {
  ProdLineNodeChangeTracker(super.element, super.previousState);

  ProdLineNodeChangeTracker.newProdLineNode(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : super.newNode() {
    var parentGraph = element.parentGraph;
    var parentGraphBuilder = parentGraph.getStateBuilder();

    switch (element.nodeType) {
      case NodeType.input:
        var inputItem = state.productionLine.inputItems.first;

        if (parentGraph.inputNodes.containsKey(inputItem)) {
          throw NodeException(
            'Input node for item $inputItem already exists in graph $parentGraph',
          );
        }

        parentGraphBuilder._inputNodes[inputItem] = element;

      case NodeType.output:
        var outputItem = state.productionLine.outputItems.first;

        if (parentGraph.outputNodes.containsKey(outputItem)) {
          throw NodeException(
            'Output node for item $outputItem already exists in graph $parentGraph',
          );
        }

        parentGraphBuilder._outputNodes[outputItem] = element;

        // Clear output cached of "grandparentGraph"
        parentGraph.parentGraph.getChangeTracker()._clearCachedOutputIndex();

      default:
        parentGraphBuilder._prodLineNodes.add(element);
    }
  }

  @override
  ProdLineNodeState get state => _cachedStateBuilder ?? previousState;

  @override
  Iterable<BasePlannerElement> determineDependants() {
    var parentDependants = state.allParents.where(
      (parent) => parent.edgeType != EdgeType.requestItems,
    );
    var childDependants = state.allChildren.where(
      (child) => child.edgeType != EdgeType.pushExcess,
    );

    return [...parentDependants, ...childDependants, element.parentGraph];
  }

  @override
  bool calculateIo() {
    ItemIoImpl constraints;

    if (element.nodeType.hasInternalConstraints) {
      constraints = state.internalConstraints!;
    } else {
      constraints = _calculateEdgeConstraints();
      stateBuilder.updateEdgeConstraints(constraints);
    }

    // Check if update is required
    if (constraints != previousState.ioData.constraints ||
        state.productionLine != previousState.productionLine) {
      var newIoData = state.productionLine.calculateIoData(constraints);

      stateBuilder.updateIoData(newIoData);
      queueUnusedIoCheck();

      if (element.nodeType.isIo) {
        element.parentGraph.getChangeTracker().queueUnusedIoCheck();
      }

      return true;
    } else {
      return false;
    }
  }

  @override
  void removeSelf() {
    for (var parent in state.allParents) {
      parent.getChangeTracker()._removeSelfFromParentOnly();
    }

    for (var child in state.allChildren) {
      child.getChangeTracker()._removeSelfFromChildOnly();
    }

    var parentGraphBuilder = element.parentGraph.getStateBuilder();

    switch (element.nodeType) {
      case NodeType.input:
        parentGraphBuilder._inputNodes.remove(
          state.productionLine.inputItems.first,
        );

      case NodeType.output:
        parentGraphBuilder._outputNodes.remove(
          state.productionLine.outputItems.first,
        );

        // Clear output cached of "grandparentGraph"
        element.parentGraph.parentGraph
            .getChangeTracker()
            ._clearCachedOutputIndex();

      default:
        parentGraphBuilder._prodLineNodes.remove(element);
    }

    _removeSelfOnly();
  }

  @override
  ProdLineNodeStateBuilder _createStateBuilder() =>
      ProdLineNodeStateBuilder.from(element, previousState);

  @override
  NodeDependencies _determineDependencies() {
    Map<InGameItem, Set<Edge>> parentDeps = Map.from(state.parents)
      ..updateAll(
        (item, edgeSet) => edgeSet
            .where((edge) => edge.edgeType == EdgeType.requestItems)
            .toSet(),
      )
      ..removeWhere((item, edgeSet) => edgeSet.isEmpty);

    Map<InGameItem, Set<Edge>> childDeps = Map.from(state.children)
      ..updateAll(
        (item, edgeSet) => edgeSet
            .where((edge) => edge.edgeType == EdgeType.pushExcess)
            .toSet(),
      )
      ..removeWhere((item, edgeSet) => edgeSet.isEmpty);

    return NodeDependencies(parentDeps: parentDeps, childDeps: childDeps);
  }

  @override
  void _removeSelfOnly() {
    _toRemove = true;

    stateBuilder
      .._parents.clear()
      .._children.clear();

    _removeSelfAndUpdateParentGraphSnapshotBuilder();
  }

  ItemIoImpl _calculateEdgeConstraints() {
    ItemIoBuilder builder = ItemIoBuilder();

    cachedDependencies.parentDeps.forEach((item, requestItemEdges) {
      builder.addToOutputs(
        item,
        requestItemEdges
            .map((edge) => edge.amount)
            .reduce((amount1, amount2) => amount1 + amount2),
      );
    });

    cachedDependencies.childDeps.forEach((item, pushExcessEdges) {
      builder.addToInputs(
        item,
        pushExcessEdges
            .map((edge) => edge.amount)
            .reduce((amount1, amount2) => amount1 + amount2),
      );
    });

    return builder.build();
  }
}
