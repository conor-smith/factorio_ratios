part of '../graph.dart';

class Vertex extends BasicUpdateable implements ProductionLine {
  ProductionLine _internalLine;
  Vertex._(this._internalLine);

  @override
  void update() {
    // TODO: implement update
    super.update();
  }
  
  @override
  ProductionLineType get type => _internalLine.type;
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