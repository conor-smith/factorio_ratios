import 'dart:collection';

import 'package:factorio_ratios/backend/factorio_objects/objects.dart';
import 'package:factorio_ratios/backend/graph/moduled_building.dart';

/// Represents entirety of the factorio base
///
/// Logically, this is a directed graph
/// with "ItemProducers" as nodes and "ItemTransport" as edges
///
/// This is intended for display within a GUI
/// As such, ItemProducers are represented as boxes
/// and ItemTransports as complex lines connecting said boxes
/// For more information on how these are drawn,
/// refer to ItemProducer and ItemTransport documentation below
///
/// Creation, deletion, and balancing of producers and transporters
/// are all handled by this object and this object alone
/// To ensure singular responsibility,
/// all constructors, setters, and methods required for controlling the graph are private
/// Users may not directly instantiate nodes, edges, etc
/// All list and maps will be unmodifiable views over the internal objects
class FactorioBase {
  final ItemContext itemContext;

  final Map<ItemProducer, List<ItemTransport>> _fullBase = {};
  final List<ImmutableModuledBuilding> _defaultBuildings = [];
  late final List<ImmutableModuledBuilding> _defaultBuildingsView =
      UnmodifiableListView(_defaultBuildings);

  FactorioBase(this.itemContext);

  /// Will add a new ProductionLine
  /// Any dependency items will result in the creation of another ItemProducer
  ///
  /// If said dependency item has only one possible recipe, a new ProductionLine with
  /// one primary item crafter will be created with constraint "implicitMinimumOutput"
  /// This same operation will occur for any dependencies of this new ProductionLine
  ///
  /// If the dependency has 0 or >1 potential recipes,
  /// An ItemSource will be created instead
  ///
  /// Cannot use "implicitMinimumOutput" in this method
  void addProductionLineNode(
      {required ProductionLineConstraint constraint,
      Map<Item, double>? ioConstraint,
      int? buildingsConstraint,
      required Map<Recipe, ImmutableModuledBuilding> primaryProductionLines,
      Map<Recipe, ImmutableModuledBuilding>? secondaryProductionLines,
      required Point centrePoint}) {
    // TODO
    throw UnimplementedError();
  }

  /// Resizes all producers based on the total number of buildings within them (where applicable)
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

  /// Sum total of netIo of all contained nodes
  Map<Item, double> get excess {
    // TODO
    throw UnimplementedError();
  }

  /// Full list of all ItemProducers
  /// WARNING: Does not update in real time
  /// You will need to retrieve this list every time a change occurs
  List<ItemProducer> get nodes => List.from(_fullBase.keys);

  /// Full list of all ItemProducers
  /// WARNING: Does not update in real time
  /// You will need to retrieve this list every time a change occurs
  List<ItemTransport> get edges => List.from(_fullBase.values);

  List<ImmutableModuledBuilding> get defaultBuildings => _defaultBuildingsView;
}

/// Represents xy co-ordinate on 2D plane
/// Intended for use in GUI
class Point {
  double _x;
  double _y;

  Point({required double x, required double y})
      : _x = x,
        _y = y;

  double get x => _x;
  double get y => _y;
}

/// Represents sides of a box
/// Intended for use in the GUI
enum BoxSide { top, bottom, left, right }

/// Represents a single "node" in the overall graph
/// netIO field gives items produced and consumed
/// connections give a map containing all input/output transports
///
/// GUI documentation
/// As the graph is intended to be displayed in a GUI, graphNodes also contain co-ordinates to be displayed graphically
/// Nodes are displayed as a resizable, draggagle rectangle
/// It's position and size are given by the corner1 and corner2 fields
/// These points represent two diagonal corners of the rectangle
/// The x and y co-ordinates will always equal a whole number, rather than a decimal
/// This is so the boxes will "snap" to position within the graph
///
/// Adjusting co-ordinates:
/// There exist two operations that adjust the x and y co-ordinates of this box: drag and resize
/// Both of them required the user to call beginDragging/Resizing at the start
/// and endDragging/Resizing at the end
/// Failure to call these methods will result in an error being thrown
/// Only one of these operations can be performed at a time within the whole graph
/// Attempting to resize / drag another producer before calling endDrag/Resize will throw an error
///
/// ItemTransport connections:
/// The positioning of ItemTransport connections is also handled by this box
/// In the GUI, every ItemTransport has to visibly connect to one side of the box
/// This is given by the .connections field
/// If one side of the box has multiple connections,
/// the connections are spaced out, and ordered by their position within the list
/// If the box is too small to properly space out connections, some will overlap
/// These connections can be modified with the .adjustConnectionOrder(...)
/// and the .changeConnectionSide(...) methods
abstract class ItemProducer {
  // The ratioGraph this node is a part of
  final FactorioBase factorioBase;

  final Point corner1;
  final Point corner2;

  final Map<BoxSide, ItemTransport> connections = {};

  ItemProducer(
      {required this.factorioBase,
      required this.corner1,
      required this.corner2});

  /// Must be called before dragging rectangle in GUI
  void beginDragging() {
    throw UnimplementedError();
  }

  /// Must be called after dragging rectangle in GUI
  void endDragging() {
    throw UnimplementedError();
  }

  /// This method allows the user to drag the rectangle around the GUI,
  /// changing the x and y values of corner1 and corner2
  /// Before calling this method, you first call .beginDragging(), and end by calling .endDragging()
  /// when .beginDragging() is called, the rectangles current position will be saved internally
  /// xOffset and yOffset will always be applied to this original x and y co-ordinates
  /// Once .endDragging() is called, the current offset is "committed" and the new position is set
  void drag({int xOffset = 0, int yOffset = 0}) {
    // TODO
    throw UnimplementedError();
  }

  /// Must call before resizing rectange in GUI
  void beginResizing() {
    throw UnimplementedError();
  }

  /// Must call after resizing rectangle in GUI
  void endResizing() {
    throw UnimplementedError();
  }

  /// This method allows the user to resize the rectangle in the GUI
  /// changing the x and y values of corner1 and corner2
  /// Before calling this method, you must first call .beginResizing(), and end by calling .endResizing()
  /// After calling .beginResizing(), the rectangle's current co-ordinates will be saved internally
  /// All calls to this method will be applied to those initial co-ordiantes
  /// Once mode is changed again, the current size is "committed"
  ///
  /// The box will have a minimum width and height of 1
  /// Any offsets that result in a width or height of 0 will internally correct to 1
  ///
  /// If two sides cross over eachother, the co-ordinates will simply be flipped
  /// Eg. Applying an offset of -10 to leftSide when leftSide is at x co-ordinate 5,
  /// and rightSide is at x co-ordinate 0
  /// will result in a rectangle where leftSide is at x co-ordinate 0,
  /// and rightSide is at x co-ordinate -5
  void resize(Map<BoxSide, int> offsets) {
    // TODO
    throw UnimplementedError();
  }

  /// Changes the position of one ItemTransport connection on a particular side
  /// relative to other connections on the same side
  /// Attempting to set newPostion to <0 or > [number of connections]
  /// will default to 0 or [number of connections]
  void changeConnectionOrder(ItemTransport transport, int newPosition) {
    // TODO
    throw UnimplementedError();
  }

  /// Changes the side a particular ItemTransport is connected to
  void changeConnectionSide(
      ItemTransport transport, BoxSide newSide, int newPosition) {
    // TODO
    throw UnimplementedError();
  }

  /// Negative numbers represent inputs / consumed items
  /// Positive numbers represent outputs
  Map<Item, double> get netIo;
}

/// Represents items flowing from one ItemProducer to another
/// Items flow from the parent to the child
/// THis object can also be queried to determine how many belts are required to
/// transport items, if applicable
///
/// GUI documentation
/// In the GUI, this edge is represented as a complex line connecting two nodes
/// This line is represented by the .points field, containing an ordered list of points in the line
/// All angles are right angles, to better represent the factorio game
/// New points/turns can be added via reverseAngle(...), goAround(...), or extendPath(...),
/// all of which are documented below
///
/// When ItemProducers are moved / being resized, or when the connectionSide of
/// a parent or child is changed, the FactorioBase will take care of adjusting
/// this object
class ItemTransport {
  final Item item;
  final ItemProducer parent;
  final ItemProducer child;
  double _amount;

  /// Only set to true if a dependency cannot produce all required output
  /// See ProductionLineConstraint for info on how this may happen
  bool _isBottleNeck = false;

  final List<Point> _points;
  late final List<Point> _pointsView = UnmodifiableListView(_points);

  ItemTransport._(
      {required this.item,
      required this.parent,
      required this.child,
      required double initialAmount,
      required List<Point> points})
      : _amount = initialAmount,
        _points = points;

  List<Point> get points => _pointsView;
  bool get isBottleNeck => _isBottleNeck;
}

/// Represents a source of items with no required inputs or crafters
/// Used for things like ore, crude oil, or other natural resources
/// But can be used for any item if the user decides it doesn't matter how a particular item is produced
///
/// Any item that has no recipe (natural resources) must be provided by an ItemSource
/// But this will also be used for items with multiple potential sources
/// After the user has picked a recipe, the ItemSource can be replaced
///
/// Cannot be resized in GUI
class ItemSource extends ItemProducer {
  final Item resource;

  // Only to be adjusted by RatioGraph object
  double _output;

  ItemSource._(
      {required this.resource,
      required double initialOutput,
      required FactorioBase factorioBase,
      required Point topRightCorner})
      : _output = initialOutput,
        super(
            factorioBase: factorioBase,
            corner1: topRightCorner,
            corner2: Point(x: topRightCorner._x - 3, y: topRightCorner._y - 3));

  @override
  Map<Item, double> get netIo => {resource: _output};
}

/// This defines what to calculate when creating a ProductionLine
/// Only one may be applied
enum ProductionLineConstraint {
  /// For PLs where a required output is explicitly set
  /// To be used with ioConstraint field
  /// The items in ioConstraint must be producible by the primary crafters
  /// in this node
  explicitMinimumOutput,

  /// For PL nodes where a required output is implicitly set
  /// To be used with ioConstraint field
  /// Only used for dependencies
  implicitMinimumOutput,

  /// For PLs which are intended to consume all excess supply of a particular item
  /// To be used with consumeAllConstraint
  consumeAllExcess,

  /// For production line nodes where a number of buildings is set
  /// Can only be applied to primary crafters
  /// To be used with buildingsConstraint
  ///
  /// WARNING: A requiredBuildings ProductionLine may not be able to produce
  /// enough items for dependants
  /// The FactorioBase will flag this by setting ItemTransport.isBottleNeck to true
  /// This is on the user to fix
  requiredBuildings
}

/// This producer represents a "traditional" production line
/// with "crafters", as represented by key-value pairs of a recipe and a ModuledBuilding
///
/// A ProductionLine will contain at least one primary crafter,
/// although multiple primary crafters can be specified
/// Secondary crafters are entirely optional
///
/// The primary crafters determine the output
/// Secondary crafters are for dependencies of the primary crafters
/// Eg. When building circuits, you may prefer to assemble copper circuits on site
/// rather than give them their own dedicated ProductionLine
/// As such, copper circuits can be added as a secondary crafter to better represent this
/// The secondary crafters will only produce enough items to feed the primary crafters
/// Furthermore, secondary crafters can also be added to support other secondary crafters
/// Eg. Assembling a satellite requires radars, which also require iron gear wheels
/// Both the radars and iron gear wheels can be added as secondary crafters
/// The iron gear wheel crafter will support the radar crafter, which supports the primary satellite crafter
///
/// If a crafter produces multiple items, excess or unnecessary items will be added to the output
///
/// Restrictions:
/// No two crafters may produce the same item
/// For recipe balancing (eg. Advanced oil processing), see "Balancer"
/// Primary crafters cannot be dependencies of one another
/// Secondary crafters must be a direct dependency of either a primary or secondary crafter
class ProductionLineNode extends ItemProducer {
  ProductionLineConstraint _constraint;
  Map<Item, double>? _ioConstraint;
  List<Item>? _consumeAllConstraint;
  Map<Recipe, int>? _buildingsConstraint;

  final Map<Recipe, ImmutableModuledBuilding> _primaryCrafters;
  final Map<Recipe, ImmutableModuledBuilding> _secondaryCrafters;

  late final Map<Recipe, ImmutableModuledBuilding> _primaryCraftersView =
      UnmodifiableMapView(_primaryCrafters);
  late final Map<Recipe, ImmutableModuledBuilding> _secondaryCraftersView =
      UnmodifiableMapView(_secondaryCrafters);

  ProductionLineNode._(
      {required ProductionLineConstraint constraint,
      Map<Item, double>? ioConstraint,
      List<Item>? consumeAllConstraint,
      Map<Recipe, int>? buildingsConstraint,
      required Map<Recipe, ImmutableModuledBuilding> primaryCrafters,
      Map<Recipe, ImmutableModuledBuilding>? secondaryCrafters,
      required super.factorioBase,
      required super.corner1,
      required super.corner2})
      : _constraint = constraint,
        _ioConstraint =
            ioConstraint != null ? UnmodifiableMapView(ioConstraint) : null,
        _consumeAllConstraint = consumeAllConstraint != null
            ? UnmodifiableListView(consumeAllConstraint)
            : null,
        _buildingsConstraint = buildingsConstraint != null
            ? UnmodifiableMapView(buildingsConstraint)
            : null,
        _primaryCrafters = primaryCrafters,
        _secondaryCrafters = secondaryCrafters ?? {} {
    // TODO: Error checking
  }

  @override
  Map<Item, double> get netIo {
    // TODO
    throw UnimplementedError();
  }

  void setConstraint(ProductionLineConstraint constraint,
      {Map<Item, double>? ioConstraint,
      List<Recipe>? consumeAllConstraint,
      Map<Recipe, int>? buildingsConstraint}) {
    // TODO
    throw UnimplementedError();
  }

  /// Can also be used to change ImmutableModuledBuilding on existing crafters
  void addOrModifyPrimaryCrafters(
      Map<Recipe, ImmutableModuledBuilding> newCrafters) {
    // TODO
    throw UnimplementedError();
  }

  void removePrimaryCrafters(List<Recipe> toRemove) {
    // TODO
    throw UnimplementedError();
  }

  /// Can also be used to change ImmutableModuledBuilding on existing crafters
  void addOrModifySecondaryCrafters(
      Map<Recipe, ImmutableModuledBuilding> newProductionLines) {
    // TODO
    throw UnimplementedError();
  }

  void removeSecondaryCrafters(List<Recipe> toRemove) {
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

  List<Item>? get consumeAllConstraint => _consumeAllConstraint;

  Map<Recipe, int>? get buildingsConstraint => _buildingsConstraint;

  Map<Recipe, ImmutableModuledBuilding> get primaryCrafters =>
      _primaryCraftersView;

  Map<Recipe, ImmutableModuledBuilding> get secondaryCrafters =>
      _secondaryCraftersView;
}

/// This is used for complicated production lines that require balancing
/// between multiple recipes with similar outputs
/// Eg. Advanced oil processing
/// Much like a production line, this also consists of crafters,
/// although it makes no distinction between primary and secondary
///
/// Restrictions:
/// No more than two crafters may produce the same item
/// All crafters must be a direct dependency or dependant of another crafter
/// At least two crafters are required. Otherwise, use a ProductionLine
/// Only has one possible constraint: requiredOutput
class Balancer extends ItemProducer {
  Map<Item, double> _requiredOutput;

  final Map<Recipe, ImmutableModuledBuilding> _crafters;
  late final Map<Recipe, ImmutableModuledBuilding> _craftersView =
      UnmodifiableMapView(_crafters);

  Balancer._(
      {required Map<Recipe, ImmutableModuledBuilding> crafters,
      required Map<Item, double> requiredOutput,
      required super.factorioBase,
      required super.corner1,
      required super.corner2})
      : _requiredOutput = Map.unmodifiable(requiredOutput),
        _crafters = crafters;

  set requiredOutput(Map<Item, double> newOutput) {
    // TODO
    throw UnimplementedError();
  }

  /// Can also be used to change ImmutableModuledBuilding on existing crafters
  void addOrModifyCrafters(Map<Recipe, ImmutableModuledBuilding> newCrafters) {
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

  @override
  Map<Item, double> get netIo {
    // TODO
    throw UnimplementedError();
  }

  Map<Item, double> get requiredOutput => _requiredOutput;

  Map<Recipe, ImmutableModuledBuilding> get crafters => _craftersView;
}

/// This is solely for launching the end game rocket
/// Calculates how long it takes to launch a rocket based on number of rocket parts produced
/// Accepts 1 item as rocket cargo and produces relevant output
class RocketLaunch extends ItemProducer {
  Item? _cargo;

  RocketLaunch._(
      {Item? cargo,
      required super.factorioBase,
      required super.corner1,
      required super.corner2})
      : _cargo = cargo;

  @override
  Map<Item, double> get netIo => throw UnimplementedError();

  set cargo(Item? newCargo) {
    throw UnimplementedError();
  }

  Item? get cargo => _cargo;
}
