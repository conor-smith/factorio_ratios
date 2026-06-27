import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'combiner.dart';
part 'io_line.dart';
part 'magic_line.dart';
part 'single_recipe.dart';
part 'single_machine_impl.dart';
part 'single_machine.dart';

/// Represents a single production line.
/// A production line is anything capable of inputting or outputting items.
/// Eg. A collection of mining drills counts as a "production line".
///
/// A call to [calculateIoData] must not have any effect on [outputItems], [inputItems], [ioRatios].
/// This means that all of these values must be determined independently.
///
/// In some scenarios, it is possible to calculate the input / output ratios.
/// before any constraints are passed.
/// In such cases, [ioRatios] should be calculated.
/// The smallest value in inputs or outputs will be set to 1.
/// All other values across both maps will be calculated relative to this.
/// This field must be calculated independently of [calculateIoData].
/// If this isn't possible, these fields will be null.
abstract mixin class ProductionLine<T extends ProductionLineIoData> {
  /// Used in [toString]
  String get name;

  /// Specifies what kind of production line this is
  ProductionLineType get productionLineType;

  /// Used in displays
  Icon? get icon;

  /// All items this production line requires
  Set<InGameItem> get inputItems;

  /// All items this production line produces
  Set<InGameItem> get outputItems;

  /// Ratios of all inputs and outputs. Smallest value will be 1, and
  /// all other values will be set relative to that value.
  /// Will only be present in production lines where it can be calculated
  /// ahead of time.
  ItemIoImpl? get ioRatios;

  /// Takes a set of input and output constraints, and produces an object representing IO.
  /// For each constraint, the production line must consume this amount or more.
  /// Eg. If two output constraints are specified, the production line must fulfill both of them.
  /// even if doing so means producing an excess of one.
  /// The same rule applies to input constraints.
  ///
  /// [ItemIoImpl.inputs] and [ItemIoImpl.outputs] must be given in items per minute
  T calculateIoData([ItemIoImpl constraints]);

  // TODO: Document
  void verifyConstraints(ItemIoImpl constraints) {
    if (!inputItems.containsAll(constraints.inputs.keys) ||
        !outputItems.containsAll(constraints.outputs.keys)) {
      throw ProductionLineException(
        'Production line $this with inputs $inputItems and outputs $outputItems could not accept constraints $constraints',
      );
    }
  }

  @override
  String toString() => name;
}

/// Represents a line output given a set of constraints.
///
/// Only the displayData should be displayed to an end user.
/// All other fiels, both here and in inherited classes,
/// should exist for utility reasons - to be used in further equations / operations.
///
/// All [ItemAmounts] and [ItemIoImpl] fieds are given in items per minute.
class ProductionLineIoData {
  /// Constraints that were used to generate this IO
  final ItemIoImpl constraints;

  /// Net input / output in items per minute.
  ///
  /// Defaults to [constraints] when no value is set.
  final ItemIoImpl io;

  /// Total production and comsumption in items per minute.
  ///
  /// May differ from [io] in situations where a production line consumes
  /// part of it's own output.
  /// Also differs in production lines like [CombinerLine] where
  /// no production actually takes place, and items are just passed through.
  ///
  /// Defaults to [io] when no value is set.
  final ItemIoImpl totalProductionAndConsumption;

  /// Electrical power consumed, given in watts
  final double electricPowerConsumption;

  /// Given in emissions per minute
  final Map<String, double> emissions;

  /// DisplayData for end user.
  /// No data in here should be used for further calculations.
  /// If any useful data exists, it should be made it's own field.
  final List<DisplayData> displayData;

  ProductionLineIoData({
    this.constraints = ItemIoImpl.empty,
    ItemIoImpl? io = ItemIoImpl.empty,
    ItemIoImpl? totalProductionAndConsumption,
    this.electricPowerConsumption = 0,
    Map<String, double> emissions = const {},
    Iterable<DisplayData> displayData = const [],
  }) : io = io ?? constraints,
       totalProductionAndConsumption =
           totalProductionAndConsumption ?? io ?? constraints,
       emissions = Map.unmodifiable(emissions),
       displayData = List.unmodifiable(displayData);

  const ProductionLineIoData.empty()
    : constraints = ItemIoImpl.empty,
      io = ItemIoImpl.empty,
      totalProductionAndConsumption = ItemIoImpl.empty,
      electricPowerConsumption = 0,
      emissions = const {},
      displayData = const [];
}

enum ProductionLineType { io, magic, singleRecipe, combiner, graph }

class ProductionLineException extends FactorioException {
  const ProductionLineException(super.message, [super.cause]);
}

class ValueAndDisplayData<T> {
  final T value;
  final List<DisplayData> displayData;

  const ValueAndDisplayData(this.value, this.displayData);
}

abstract class ItemIo {
  ItemAmounts get inputs;
  ItemAmounts get outputs;

  bool get isEmpty => inputs.isEmpty && outputs.isEmpty;
  bool get isNotEmpty => inputs.isNotEmpty || outputs.isNotEmpty;

  const ItemIo();
}

/// An immutable, and validated implementation of [ItemIo]
/// No value in [inputs] or [outputs] may be less than 0
class ItemIoImpl extends ItemIo {
  static const empty = ItemIoImpl._empty();

  @override
  final ItemAmounts inputs;
  @override
  final ItemAmounts outputs;

  const ItemIoImpl._empty() : inputs = const {}, outputs = const {};

  ItemIoImpl({ItemAmounts inputs = const {}, ItemAmounts outputs = const {}})
    : inputs = Map.unmodifiable(inputs),
      outputs = Map.unmodifiable(outputs) {
    inputs.forEach((input, amount) {
      if (amount < 0) {
        throw ProductionLineException('Input $input had invalid value $amount');
      }
    });

    outputs.forEach((output, amount) {
      if (amount < 0) {
        throw ProductionLineException(
          'Output $output had invalid value $amount',
        );
      }
    });
  }

  @override
  bool operator ==(Object other) {
    return super == other ||
        (other is ItemIoImpl &&
            compareMaps(other.inputs, inputs) &&
            compareMaps(other.outputs, outputs));
  }

  @override
  int get hashCode => inputs.entries
      .followedBy(outputs.entries)
      .map((entry) => entry.key.hashCode * entry.value.hashCode)
      .reduce((val1, val2) => val1 + val2);

  @override
  String toString() => 'inputs: $inputs, outputs: $outputs';
}
