part of '../production_line.dart';

/*
 * Rules for this production line are as follows
 * I/O is given by 1 or more I/O nodes
 * I/O nodes contain an InfiniteLine
 * A node containing an InfiniteLine is not necessarily I/O (eg. Could represent a resource patch)
 * Itemflow is unidirectional - all flow begins at input and terminates at output
 * There can be an arbitrary number of production line nodes between input and output nodes
 * Circular flows are not permitted
 * Every item may only have 1 producer
 */
class PlanetaryBase extends ProductionLine {


  @override
  // TODO: implement ioPerSecond
  Map<ItemData, double> get totalIoPerSecond => throw UnimplementedError();

  @override
  void update(Map<ItemData, double> requirements) {
    // TODO: implement update
  }
  
  @override
  // TODO: implement ingredientsPerSecond
  Map<ItemData, double> get ingredientsPerSecond => throw UnimplementedError();
  
  @override
  // TODO: implement productsPerSecond
  Map<ItemData, double> get productsPerSecond => throw UnimplementedError();
  
}

class ProdLineNode {
  
}