part of 'node.dart';

abstract class AbstractNodeState implements NodeState {
  @override
  final NodeGeometryImpl nodeGeometry;

  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  AbstractNodeState.initial({required this.nodeGeometry})
    : parents = const {},
      children = const {};

  AbstractNodeState(
    NodeElement node, {
    required ProductionLine productionLine,
    required this.nodeGeometry,
    required Iterable<Edge> parents,
    required Iterable<Edge> children,
  }) : parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children) {
    // Make sure that, for each item outputted to acceptExcess edges,
    // The sum of the edge percentages does not exceed 1.0
    Map<InGameItem, double> excessOutputPercentages = Map.fromIterable(
      productionLine.outputItems,
      value: (item) => 0.0,
    );

    for (var parent in this.parents) {
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

    // Make sure that, for each item consumed via requestInput edges,
    // The sum of the edge percentages does not exceed 1.0
    Map<InGameItem, double> requestInputPercentages = Map.fromIterable(
      productionLine.inputItems,
      value: (item) => 0.0,
    );

    for (var child in this.children) {
      if (child.edgeType == EdgeType.requestItems) {
        requestInputPercentages.update(
          child.item,
          (percentage) => percentage + child.percentage,
        );
      }
    }

    requestInputPercentages.forEach((item, totalPercentage) {
      // Rounded down to lowest 0.01
      var roundedPercentage = (totalPercentage * 100).floor();

      if (roundedPercentage > 100) {
        throw NodeException(
          'Node $node requestItem edges for item $item percentage sum == $totalPercentage',
        );
      }
    });
  }
}
