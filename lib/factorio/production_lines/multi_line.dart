part of '../production_line.dart';

class PlanetaryBase extends ProductionLine {
  @override
  Map<ItemData, double> get totalIoPerSecond => throw UnimplementedError();

  @override
  void update(Map<ItemData, double> requirements) {}

  @override
  Map<ItemData, double> get ingredientsPerSecond => throw UnimplementedError();

  @override
  Map<ItemData, double> get productsPerSecond => throw UnimplementedError();
}

enum NodeType { resource, disposal, input, output, productionLine }

class ProdLineNode {
  final PlanetaryBase parentBase;
  NodeType _type;
  ProductionLine? _line;
  Map<ItemData, double> _requirements;

  ProdLineNode._(
    this.parentBase,
    this._type, {
    ProductionLine? line,
    Map<ItemData, double>? requirements,
  }) : _line = line,
       _requirements = requirements ?? {};
}
