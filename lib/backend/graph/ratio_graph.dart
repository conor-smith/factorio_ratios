import 'dart:collection';

import 'package:factorio_ratios/backend/factorio_objects/objects.dart';
import 'package:factorio_ratios/backend/graph/moduled_building.dart';

/// Represents entirety of ratio graph
/// Creation, deletion, and balancing of nodes are all handled by this object
/// Anytime a new node is added to the graph, all required dependant nodes will be created to supply it
class RatioGraph {
  final ItemContext itemContext;

  final Map<GraphNode, GraphEdge> _fullGraph = {};
  final List<ImmutableModuledBuilding> _defaultBuildings = [];
  late final List<ImmutableModuledBuilding> _defaultBuildingsView;

  RatioGraph(this.itemContext) {
    _defaultBuildingsView = UnmodifiableListView(_defaultBuildings);
  }

  /// Will add a new productionLineNode
  /// All required dependency nodes will also be created
  /// with constraint "implicitMinimumOutput"
  /// Cannot use "implicitMinimumOutput" in this method
  void addProductionLineNode(
      {required ProductionLineConstraint constraint,
      Map<Item, double>? ioConstraint,
      int? buildingsConstraint,
      required Map<Recipe, ImmutableModuledBuilding> primaryProductionLines,
      Map<Recipe, ImmutableModuledBuilding>? secondaryProductionLines}) {
    // TODO
    throw UnimplementedError();
  }

  /// Resizes all nodes based on the total number of buildings within them
  void resizeAllBasedOnNumberOfBuildings() {
    // TODO
    throw UnimplementedError();
  }

  /// If applyToExisting == true,
  /// All production lines or balancers with recipes produced by the old building
  /// will be replaced by the new one
  void editDefaultBuilding(ImmutableModuledBuilding oldBuilding,
      ImmutableModuledBuilding newBuilding,
      {bool applyToExisting = false}) {
    // TODO
    throw UnimplementedError();
  }

  /// Removes a node from the graph
  /// If the node is a production line node or balancer node, all production lines will be moved
  /// the secondary slots within dependants
  /// Will throw error if removal is not possible
  void removeNode(GraphNode node) {
    // TODO
    throw UnimplementedError();
  }

  /// Sum total of netIo of all contained nodes
  Map<Item, double> get excess {
    // TODO
    throw UnimplementedError();
  }

  List<GraphNode> get nodes => List.from(_fullGraph.keys);
  List<GraphEdge> get edges => List.from(_fullGraph.values);
  List<ImmutableModuledBuilding> get defaultBuildings => _defaultBuildingsView;
}

/// Represents "mode" of a graph node within GUI
/// This mode controls what operations can be performed on the node
enum GraphNodeMode {
  /// This mode allows "ordinary" operations pertaining to the actual ratio graph
  /// Eg. Adding recipes to ProductionLineNodes, adjusting output of ResourceNodes, etc
  defaultMode,

  /// This mode is to be used when a node is being dragged around within the co-ordinates
  dragMode,

  /// This mode is to be used when resizing the node within the co-ordinates
  resizeMode
}

/// Represents a single node in the ratio graph
/// Has a net input/output given by netIo field
/// Negative numbers in netIo represent inputs, positive numbers represent output
///
/// As the graph is intended to be displayed in a GUI, graphNodes also contain co-ordinates to be displayed in a grid
/// Nodes are displayed as a resizable, draggagle rectangle
/// It's co-ordinates and size are given by the fields corner1x, corner1y, corner2x and corner2y
/// These fields represent two diagonal corners of the rectangle
/// Ints are used here because I want the rectangles to "snap to" certain co-ordinates
/// This same constraint is not applied to edges
///
/// In order to move or resize the rectangle, you must first set the appropriate mode
abstract class GraphNode {
  int _corner1x;
  int _corner1y;
  int _corner2x;
  int _corner2y;

  // Supplied and managed by RatioGraph object
  final List<GraphEdge> edges;

  // Initial mode should always be ratiosMode
  GraphNodeMode _mode = GraphNodeMode.defaultMode;

  GraphNode(
      {required int corner1x,
      required int corner1y,
      required int corner2x,
      required int corner2y,
      required this.edges})
      : _corner1x = corner1x,
        _corner1y = corner1y,
        _corner2x = corner2x,
        _corner2y = corner2y;

  set mode(GraphNodeMode newMode) {
    // TODO
    throw UnimplementedError();
  }

  /// Before calling this method, you must set mode = dragMode
  /// When mode is changed to dragMode, the rectangles current position will be saved internally
  /// xOffset and yOffset will always be applied to this original x and y co-ordiantes
  /// Once mode is changed again, the current offset is "committed"
  void drag({int xOffset = 0, int yOffset = 0}) {
    // TODO
    throw UnimplementedError();
  }

  /// Before calling this method, you must set mode = resizeMode
  /// When mode is changed to resizeMode, the rectangle's current size will be saved internally
  /// All calls to this method will be applied to those initial co-ordiantes
  /// Once mode is changed again, the current size is "committed"
  ///
  /// Each field represents a an offset as applied to a side of the rectangle
  /// Eg. maxXSideOffset represents the offset applied to the side of the rectangle with the highest x co-ordinate
  ///
  /// The box will have a minimum width and height of 1
  /// Any offsets that result in a width or height of 0 will internally correct to 1
  ///
  /// If two sides cross over eachother, the co-ordinates will simply be flipped
  void resize(
      {int maxXSideOffset = 0,
      int minXSideOffset = 0,
      int maxYSideOffset = 0,
      int minYSideOffset = 0}) {
    // TODO
    throw UnimplementedError();
  }

  int get corner1x => _corner1x;
  int get corner1y => _corner1y;
  int get corner2x => _corner2x;
  int get corner2y => _corner2y;

  GraphNodeMode get mode => _mode;

  // To be implemented by children
  Map<Item, double> get netIo;
}

/// Represents a line on the gui, drawn as part of an edge
/// Must be at a right angle. No diagonal lines
class GraphEdgeLine {
  // TODO
}

/// Represents a directional edge within the graph
/// Items flow from the parent to the child
/// As this is intended to be displayed in a GUI, the edge itself consists of one or more lines
/// linking the two nodes together
/// These lines exist only at right angles to better match factorio itself
/// The edge itself can connect to any side of the parent and child nodes
class GraphEdge {
  final Item item;
  final GraphNode parent;
  final GraphNode child;
  double _amount;

  final List<GraphEdgeLine> _guiLines;
  late final List<GraphEdgeLine> lines;

  GraphEdge._(
      {required this.item,
      required this.parent,
      required this.child,
      required double initialAmount,
      required List<GraphEdgeLine> lines})
      : _amount = initialAmount,
        _guiLines = lines {
    this.lines = UnmodifiableListView(_guiLines);
  }
}

/// Represents a node with an output but no required input
/// Used for things like ore, crude oil, or other natural resources
/// But can be used for any item if the user decides it doesn't matter how a particular item is produced
/// Will also be initially used for items with more than one potential source
/// This allows the user to pick from several potential recipes
///
/// This node cannot be resized
class ResourceNode extends GraphNode {
  final Item resource;

  // Only to be adjusted by RatioGraph object
  double _output;

  ResourceNode._(
      {required this.resource,
      required double initialOutput,
      required super.corner1x,
      required super.corner1y,
      required super.corner2x,
      required super.corner2y,
      required super.edges})
      : _output = initialOutput;

  @override
  set mode(GraphNodeMode newMode) {
    // TODO
    throw UnimplementedError();
    super.mode = mode;
  }

  @override
  Map<Item, double> get netIo => {resource: _output};
}

/// This defines what to calculate when creating a ProductionLineNode
/// Only one may be applied
enum ProductionLineConstraint {
  /// For PL nodes where a required output is explicitly set
  /// To be used with ioConstraint field
  /// The items in ioConstraint must be producible by the primary production lines
  /// in this node
  explicitMinimumOutput,

  /// For PL nodes where a required output is implicitly set
  /// eg. A dependency node
  implicitMinimumOutput,

  /// For production line nodes where a number of buildings is set
  /// In order to use this constraint, a production line node may only have one
  /// primary production line as this is where the constraint will apply
  requiredBuildings
}

/// This node represents a "traditional" production line
/// In this context, a production line is a recipe, and the buildings that craft said recipe
///
/// A production line node will contain at least one primary production line,
/// although multiple primary production lines can be specified
/// Optionally, several secondary production line nodes can be added
///
/// The primary production lines determine the output of this node
/// Secondary production lines are for potential dependencies of the primary production lines
/// Eg. When building circuits, you may prefer to assemble copper circuits on site
/// rather than give them their own dedicated node
/// As such, copper circuits can be added as a secondary production line to better represent that
/// The secondary production lines will produce only what is required to feed the primary production lines
/// Furthermore, secondary production lines can also be added to support other secondary production lines
/// Eg. Assembling a satellite requires radars, which also require iron gear wheels
/// Both the radars and iron gear wheels can be added to secondary production lines
/// Although iron gear wheels are not a direct dependency of satellites, they are a dependency of radars
///
/// If a any production line produces more than one item, excess or unnecessary items will be added to the node output
///
/// No two production lines may produce the same item
/// For recipe balancing (eg. Advanced oil processing), see "BalancerNode"
/// A primary production line cannot be a direct dependency of another primary production line
/// Secondary production lines must be a direct dependency of either a primary or secondary production line
class ProductionLineNode extends GraphNode {
  ProductionLineConstraint _constraint;
  Map<Item, double>? _ioConstraint;
  int? _buildingsConstraint;

  final Map<Recipe, ImmutableModuledBuilding> _primaryPls;
  final Map<Recipe, ImmutableModuledBuilding> _secondaryPls;
  late final Map<Recipe, ImmutableModuledBuilding> _primaryPlsView;
  late final Map<Recipe, ImmutableModuledBuilding> _secondaryPlsView;

  ProductionLineNode._(
      {required ProductionLineConstraint constraint,
      Map<Item, double>? ioConstraint,
      int? buildingsConstraint,
      required Map<Recipe, ImmutableModuledBuilding> primaryProductionLines,
      Map<Recipe, ImmutableModuledBuilding>? secondaryProductionLines,
      required super.corner1x,
      required super.corner1y,
      required super.corner2x,
      required super.corner2y,
      required super.edges})
      : _constraint = constraint,
        _ioConstraint = ioConstraint,
        _buildingsConstraint = buildingsConstraint,
        _primaryPls = primaryProductionLines,
        _secondaryPls = secondaryProductionLines ?? {} {
    // TODO: Error checking
    _primaryPlsView = UnmodifiableMapView(_primaryPls);
    _secondaryPlsView = UnmodifiableMapView(_secondaryPls);
  }

  @override
  Map<Item, double> get netIo {
    // TODO
    throw UnimplementedError();
  }

  void setConstraint(ProductionLineConstraint constraint,
      {Map<Item, double>? ioConstraint, int? buildingsConstraint}) {
    // TODO
    throw UnimplementedError();
  }

  /// Can also be used to change ImmutableModuledBuilding on existing production lines
  void addOrModifyPrimary(
      Map<Recipe, ImmutableModuledBuilding> newProductionLines) {
    // TODO
    throw UnimplementedError();
  }

  void removePrimary(List<Recipe> toRemove) {
    // TODO
    throw UnimplementedError();
  }

  /// Can also be used to change ImmutableModuledBuilding on existing production lines
  void addOrModifySecondary(
      Map<Recipe, ImmutableModuledBuilding> newProductionLines) {
    // TODO
    throw UnimplementedError();
  }

  void removeSecondary(List<Recipe> toRemove) {
    // TODO
    throw UnimplementedError();
  }

  /// Allows user to get the individual input of each building for a particular recipe
  /// Useful for cyclical recipes that have an item as both input and output
  /// Eg. Coal Liquefaction
  Map<Item, double> getBuildingInput(Recipe recipe) {
    // TODO
    throw UnimplementedError();
  }

  /// Allows user to get the individual output of each building for a particular recipe
  /// Useful for cyclical recipes that have an item as both input and output
  /// Eg. Coal Liquefaction
  Map<Item, double> getBuildingOutput(Recipe recipe) {
    // TODO
    throw UnimplementedError();
  }

  Map<Recipe, double> get buildingsPerRecipe {
    // TODO
    throw UnimplementedError();
  }

  double get totalConsumption {
    // TODO
    throw UnimplementedError();
  }

  double get totalPowerDrain {
    // TODO
    throw UnimplementedError();
  }

  double get totalPollution {
    // TODO
    throw UnimplementedError();
  }

  ProductionLineConstraint get constraint => _constraint;

  Map<Item, double>? get ioConstraint => _ioConstraint;

  int? get buildingsConstraint => _buildingsConstraint;

  Map<Recipe, ImmutableModuledBuilding> get primaryProductionLines =>
      _primaryPlsView;

  Map<Recipe, ImmutableModuledBuilding> get secondaryProductionLines =>
      _secondaryPlsView;
}

/// This is used for complicated production lines that require balancing
/// between multiple recipes with similar outputs
/// Eg. Advanced oil processing
class BalancerNode extends GraphNode {
  final Map<Recipe, ImmutableModuledBuilding> _pls;
  late final Map<Recipe, ImmutableModuledBuilding> productionLines;

  BalancerNode._(
      {required Map<Recipe, ImmutableModuledBuilding> productionLines,
      required super.edges,
      required super.corner1x,
      required super.corner1y,
      required super.corner2x,
      required super.corner2y})
      : _pls = productionLines {
    this.productionLines = UnmodifiableMapView(productionLines);
  }

  @override
  Map<Item, double> get netIo {
    // TODO
    throw UnimplementedError();
  }
}
