part of 'node.dart';

abstract class ProdLineNodeState implements NodeState {
  ItemIo? get requirements;

  ProductionLine get productionLine;
}

class ProdLineNodeStateImpl implements ProdLineNodeState, ToJson {
  @override
  final ItemIo? requirements;
  @override
  final NodeGeometryImpl geometry;
  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  @override
  final ProductionLine productionLine;

  @override
  final ProductionLineIo io;

  ProdLineNodeStateImpl._initial({
    required this.requirements,
    required this.productionLine,
    required this.geometry,
    required this.io,
  }) : parents = const {},
       children = const {};

  ProdLineNodeStateImpl(
    ProdLineNode node, {
    this.requirements,
    required this.productionLine,
    required this.io,
    required this.geometry,
    required this.parents,
    required this.children,
  }) {
    node.nodeType.verify(node.parentGraph, this);
    _verifyPercentages(node);
    // TODO: Verify IO Edges and priority edges
  }

  void _verifyPercentages(ProdLineNode node) {
    // Make sure that, for each item outputted to pushExcess edges,
    // The sum of the edge percentages does not exceed 1.0
    Map<InGameItem, double> excessOutputPercentages = Map.fromIterable(
      productionLine.outputItems,
      value: (item) => 0.0,
    );

    for (var parent in parents) {
      if (parent.edgeType == EdgeType.pushExcess) {
        excessOutputPercentages.update(
          parent.item,
          (percentage) => percentage + parent.percentage,
        );
      }
    }

    excessOutputPercentages.forEach((item, totalPercentage) {
      // Round down to nearest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node pushExcess edges for item $item percentage sum == $totalPercentage',
        );
      }
    });

    // Make sure that, for each item requested via requestInput edges,
    // The sum of the edge percentages does not exceed 1.0
    Map<InGameItem, double> requestInputPercentages = Map.fromIterable(
      productionLine.inputItems,
      value: (item) => 0.0,
    );

    for (var child in children) {
      if (child.edgeType == EdgeType.requestItems) {
        requestInputPercentages.update(
          child.item,
          (percentage) => percentage + child.percentage,
        );
      }
    }

    requestInputPercentages.forEach((item, totalPercentage) {
      // Round down to nearest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node requestInput edges for item $item percentage sum == $totalPercentage',
        );
      }
    });
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
