import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/utility/utility.dart';

part 'magic_line.dart';
part 'single_recipe.dart';
part 'single_machine.dart';

/// Represents a single production line.
/// A production line is anything capable of inputting or outputting items.
/// Eg. A collection of mining drills counts as a "production line".
///
/// A call to [calculate] must not have any effect on [outputItems], [inputItems], [inputRatios], or [outputRatios].
/// This means that all of these values must be determined independently.
///
/// In some scenarios, it is possible to calculate the input / output ratios.
/// before any constraints are passed.
/// If this is the case, both [inputRatios] and [outputRatios] will be populate.
/// The smallest value in inputs or outputs will be set to 1.
/// All other values across both maps will be calculated relative to this.
/// This field must be calculated independently of [calculate].
/// If this isn't possible, these fields will be null.
abstract interface class ProductionLine<T extends ProductionLineIo> {
  /// Used in [toString]
  String get name;

  /// Specifies what kind of production line this is
  String get type;

  /// Used in displays
  EntityPrototype? get icon;

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

  /// Net input / output in items per minute
  final ItemIo netIo;

  /// Total input / output in items per minute.
  /// May differ from [netIo] in situations where a production line consumes
  /// part of it's own output
  final ItemIo totalIo;

  /// Electrical power consumed given in watts
  final double electricPowerConsumption;

  /// Given in emissions per minute
  final Map<String, double> emissions;

  /// DisplayData for end user
  /// No data in here should be used for math or further operations
  /// If any useful data exists, it should be made it's own field
  final List<DisplayData> displayData;

  ProductionLineIo({
    required this.constraints,
    required this.netIo,
    required this.totalIo,
    required this.electricPowerConsumption,
    required Map<String, double> emissions,
    required Iterable<DisplayData> displayData,
  }) : emissions = Map.unmodifiable(emissions),
       displayData = List.unmodifiable(displayData);
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
      .map((entry) => entry.key.hashCode * entry.value.ceil())
      .reduce((val1, val2) => val1 + val2);
}
