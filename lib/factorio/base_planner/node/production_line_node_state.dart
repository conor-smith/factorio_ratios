part of 'node.dart';

abstract class ProdLineNodeState {
  ItemIo? get internalConstraints;
  ItemIo get edgeConstraints;
  ItemIo get itemIo;

  ProductionLine get productionLine;

  Set<Edge> get parents;
  Set<Edge> get children;
  ProductionLineIoData get ioData;
  NodeGeometryImpl get geometry;
}

class ProdLineNodeStateImpl implements ProdLineNodeState, ToJson {
  static const uninitialised = ProdLineNodeStateImpl._uninitialised();

  @override
  final ItemIoImpl? internalConstraints;
  @override
  final ItemIoImpl edgeConstraints;
  @override
  final ItemIoImpl itemIo;
  @override
  final NodeGeometryImpl geometry;
  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  @override
  final ProductionLine productionLine;

  @override
  final ProductionLineIoData ioData;

  ProdLineNodeStateImpl(
    ProdLineNode node, {
    required this.internalConstraints,
    required this.edgeConstraints,
    required this.itemIo,
    required this.productionLine,
    required this.ioData,
    required this.geometry,
    required this.parents,
    required this.children,
  }) {
    switch (node.nodeType) {
      case NodeType.combiner:
        if (productionLine.productionLineType != ProductionLineType.combiner) {
          throw const NodeException(
            'Combiner node must have combiner production line',
          );
        }
        continue noInternalConstraints;

      case NodeType.input:
      case NodeType.output:
        if (productionLine.productionLineType != ProductionLineType.io) {
          throw const NodeException('IO node must have IO production line');
        }
        continue noInternalConstraints;

      case NodeType.producer:
      case NodeType.consumer:
        if (internalConstraints == null) {
          throw NodeException(
            'Node of type ${node.nodeType} must set internal constraints',
          );
        }

      noInternalConstraints:
      case NodeType.resource:
      case NodeType.productionLine:
      case NodeType.disposal:
        if (internalConstraints != null) {
          throw NodeException(
            'Node of type ${node.nodeType} may not have internal constraints',
          );
        }
    }

    // Make sure that, for each item outputted to pushExcess and weakPushExcess edges,
    // All weakPushExcess priorities are properly numbered
    // The sum of the pushExcess percentages does not exceed 1.0
    Map<InGameItem, List<int>> weakPushPriorities = Map.fromIterable(
      productionLine.outputItems,
      value: (_) => [],
    );
    Map<InGameItem, double> pushPercentages = Map.fromIterable(
      productionLine.outputItems,
      value: (item) => 0.0,
    );

    for (var parent in parents) {
      if (parent.edgeType == EdgeType.weakPushExcess) {
        weakPushPriorities.update(
          parent.item,
          (priorities) => priorities..add(parent.priority),
        );
      } else if (parent.edgeType == EdgeType.pushExcess) {
        pushPercentages.update(
          parent.item,
          (percentage) => percentage + parent.percentage,
        );
      }
    }

    weakPushPriorities.forEach((item, priorities) {
      for (var i = 0; i < priorities.length; i++) {
        if (!priorities.contains(i + 1)) {
          throw NodeException(
            'Node $node is missing output edge with priority ${i + 1} for item $item',
          );
        }
      }
    });
    pushPercentages.forEach((item, totalPercentage) {
      // Round down to nearest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node pushExcess edges for item $item percentage sum == $totalPercentage',
        );
      }
    });

    // Make sure that, for each item requested via requestItems and weakRequestItem edges,
    // All weakRequestItem priorities are properly numbered
    // The sum of the requestItem percentages does not exceed 1.0
    Map<InGameItem, List<int>> weakRequestPriorities = Map.fromIterable(
      productionLine.inputItems,
      value: (_) => [],
    );
    Map<InGameItem, double> requestPercentages = Map.fromIterable(
      productionLine.inputItems,
      value: (item) => 0.0,
    );

    for (var child in children) {
      if (child.edgeType == EdgeType.weakRequestItems) {
        weakRequestPriorities.update(
          child.item,
          (priorities) => priorities..add(child.priority),
        );
      } else if (child.edgeType == EdgeType.requestItems) {
        requestPercentages.update(
          child.item,
          (percentage) => percentage + child.percentage,
        );
      }
    }

    weakRequestPriorities.forEach((item, priorities) {
      for (var i = 0; i < priorities.length; i++) {
        if (!priorities.contains(i + 1)) {
          throw NodeException(
            'Node $node is missing output edge with priority ${i + 1} for item $item',
          );
        }
      }
    });
    requestPercentages.forEach((item, totalPercentage) {
      // Round down to nearest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node requestInput edges for item $item percentage sum == $totalPercentage',
        );
      }
    });
  }

  const ProdLineNodeStateImpl._uninitialised()
    : internalConstraints = null,
      edgeConstraints = ItemIoImpl.empty,
      itemIo = ItemIoImpl.empty,
      geometry = NodeGeometryImpl.uninitialised,
      parents = const {},
      children = const {},
      productionLine = ProductionLine.uninitialised,
      ioData = ProductionLineIoData.uninitialised;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
