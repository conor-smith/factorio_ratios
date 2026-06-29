part of 'node.dart';

abstract class ProdLineNodeState {
  ItemIo? get internalConstraints;
  ItemIo get edgeConstraints;
  ItemIo get itemIo;

  ProductionLine get productionLine;

  Map<InGameItem, Set<Edge>> get parents;
  Map<InGameItem, Set<Edge>> get children;
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
  final Map<InGameItem, Set<Edge>> parents;
  @override
  final Map<InGameItem, Set<Edge>> children;

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
    required Map<InGameItem, Set<Edge>> parents,
    required Map<InGameItem, Set<Edge>> children,
  }) : parents = Map.unmodifiable(
         parents.map((item, edges) => MapEntry(item, Set.unmodifiable(edges))),
       ),
       children = Map.unmodifiable(
         children.map((item, edges) => MapEntry(item, Set.unmodifiable(edges))),
       ) {
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
    // - All weakPushExcess priorities are properly numbered
    // - The sum of the pushExcess percentages does not exceed 1.0
    parents.forEach((item, itemEdges) {
      var prioritiesList = itemEdges
          .where((edge) => edge.edgeType == EdgeType.weakPushExcess)
          .map((edge) => edge.priority)
          .toSet();

      for (var i = 0; i < prioritiesList.length; i++) {
        if (!prioritiesList.contains(i + 1)) {
          throw NodeException(
            'Node $node is missing output edge with priority ${i + 1} for item $item',
          );
        }
      }

      // Round to lowest 0.01
      var percentageSum = itemEdges
          .where((edge) => edge.edgeType == EdgeType.pushExcess)
          .map((edge) => edge.percentage)
          .fold(0.0, (val1, val2) => val1 + val2);

      if ((percentageSum * 100).floor() > 100) {
        throw NodeException(
          'Output edges for item $item on node $node percentages sums to value $percentageSum',
        );
      }
    });

    // Make sure that, for each item consumed via requestItems and weakRequestItems edges,
    // - All weakPushExcess priorities are properly numbered
    // - The sum of the pushExcess percentages does not exceed 1.0
    children.forEach((item, itemEdges) {
      var prioritiesList = itemEdges
          .where((edge) => edge.edgeType == EdgeType.weakRequestItems)
          .map((edge) => edge.priority)
          .toSet();

      for (var i = 0; i < prioritiesList.length; i++) {
        if (!prioritiesList.contains(i + 1)) {
          throw NodeException(
            'Node $node is missing input edge with priority ${i + 1} for item $item',
          );
        }
      }

      // Round to lowest 0.01
      var percentageSum = itemEdges
          .where((edge) => edge.edgeType == EdgeType.requestItems)
          .map((edge) => edge.percentage)
          .fold(0.0, (val1, val2) => val1 + val2);

      if ((percentageSum * 100).floor() > 100) {
        throw NodeException(
          'Input edges for item $item on node $node percentages sums to value $percentageSum',
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
