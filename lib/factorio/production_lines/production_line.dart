import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/utility/utility.dart';

part 'combiner.dart';
part 'magic_line.dart';
part 'single_recipe.dart';
part 'single_machine_impl.dart';
part 'single_machine.dart';

/// Represents a single production line.
/// A production line is anything capable of inputting or outputting items.
/// Eg. A collection of mining drills counts as a "production line".
///
/// A call to [calculate] must not have any effect on [outputItems], [inputItems], [ioRatios].
/// This means that all of these values must be determined independently.
///
/// In some scenarios, it is possible to calculate the input / output ratios.
/// before any constraints are passed.
/// In such cases, [ioRatios] should be calculated.
/// The smallest value in inputs or outputs will be set to 1.
/// All other values across both maps will be calculated relative to this.
/// This field must be calculated independently of [calculate].
/// If this isn't possible, these fields will be null.
abstract mixin class ProductionLine<T extends ProductionLineIo> {
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
  ItemIo? get ioRatios;

  /// Takes a set of input and output constraints, and produces an object representing IO.
  /// For each constraint, the production line must consume this amount or more.
  /// Eg. If two output constraints are specified, the production line must fulfill both of them.
  /// even if doing so means producing an excess of one.
  /// The same rule applies to input constraints.
  ///
  /// [ItemIo.inputs] and [ItemIo.outputs] must be given in items per minute
  T calculate(ItemIo constraints);

  // TODO: Document
  void verifyConstraints(ItemIo constraints) {
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
/// All [ItemAmounts] fieds are given in items per minute.
class ProductionLineIo {
  /// Constraints that were used to generate this IO
  final ItemIo constraints;

  /// Net input / output in items per minute.
  ///
  /// Defaults to [constraints] when no value is set.
  final ItemIo io;

  /// Total production and comsumption in items per minute.
  ///
  /// May differ from [io] in situations where a production line consumes
  /// part of it's own output.
  /// Also differs in production lines like [CombinerLine] where
  /// no production actually takes place, and items are just passed through.
  ///
  /// Defaults to [io] when no value is set.
  final ItemIo totalProductionAndConsumption;

  /// Electrical power consumed, given in watts
  final double electricPowerConsumption;

  /// Given in emissions per minute
  final Map<String, double> emissions;

  /// DisplayData for end user.
  /// No data in here should be used for further calculations.
  /// If any useful data exists, it should be made it's own field.
  final List<DisplayData> displayData;

  ProductionLineIo({
    this.constraints = ItemIo.empty,
    ItemIo? io = ItemIo.empty,
    ItemIo? totalProductionAndConsumption,
    this.electricPowerConsumption = 0,
    Map<String, double> emissions = const {},
    Iterable<DisplayData> displayData = const [],
  }) : io = io ?? constraints,
       totalProductionAndConsumption =
           totalProductionAndConsumption ?? io ?? constraints,
       emissions = Map.unmodifiable(emissions),
       displayData = List.unmodifiable(displayData);

  const ProductionLineIo.empty()
    : constraints = ItemIo.empty,
      io = ItemIo.empty,
      totalProductionAndConsumption = ItemIo.empty,
      electricPowerConsumption = 0,
      emissions = const {},
      displayData = const [];
}

class ProductionLineException extends FactorioException {
  const ProductionLineException(super.message, [super.cause]);
}

class ValueAndDisplayData<T> {
  final T value;
  final List<DisplayData> displayData;

  const ValueAndDisplayData(this.value, this.displayData);
}

class ItemIo {
  static const empty = ItemIo._empty();

  final ItemAmounts inputs;
  final ItemAmounts outputs;

  const ItemIo._empty() : inputs = const {}, outputs = const {};

  ItemIo({ItemAmounts inputs = const {}, ItemAmounts outputs = const {}})
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
        (other is ItemIo &&
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

enum ProductionLineType { io, magic, singleRecipe, combiner, graph }
