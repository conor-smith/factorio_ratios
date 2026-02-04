part of '../graph.dart';

enum VertexType {noRecipe, singleRecipe, multiRecipe}

class Vertex extends BasicUpdateable implements ProductionLine {
  ProductionLine _internalLine;
  VertexType _type;

  Vertex._(this._internalLine, this._type);

  @override
  void update() {
    // TODO: implement update
    super.update();
  }

  VertexType get type => _type;

  @override
  Map<ItemData, double> get ioPerSecond => _internalLine.ioPerSecond;
}

class Edge {
  final Vertex parent;
  final Vertex child;
  final ItemData itemData;
  double _amount;

  Edge._(this.parent, this.child, this.itemData, this._amount);

  double get amount => _amount;
}