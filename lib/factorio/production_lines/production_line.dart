import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';

part 'magic_line.dart';
part 'single_recipe.dart';
part 'single_machine.dart';

/// Represents a single production line
/// A production line is anything capable of inputting or outputting items
/// Eg. A collection of mining drills counts as a "production line"
///
/// [calculate] takes a set of input and output constraints, and produces an object representing IO
/// For each constraint, the production line must consume this amount or more
/// Eg. If two output constraints are specified, the production line must fulfill both of them
/// even if doing so means producing an excess of one
/// The same rule applies to input constraints
///
/// A call to [calculate] must not have an effect on [allInputs], [allOutputs], or [netIoRatios]
/// This means that all of these values must be determined independantly
///
/// [allInputs] and [allOutputs] must not share any items
/// This means that only net IO is taken into account when determining input and output sets
/// Eg. The kovarex process consumes 40 U-235, and 5 U-238 to produce 41 U-235 and 2 U-238
/// This means the net IO of this recipe consumes 3 U-238 to produce 1 U-235
/// As such, a production line representing this would have input {U-238} and output {U-235}
abstract mixin class ProductionLine<T extends ProductionLineIoData> {
  /// Used in [toString]
  String get name;

  /// Specifies what kind of production line this is
  String get type;

  /// Used in displays
  List<IconData>? get icon;

  Set<InGameItem> get allOutputs;
  Set<InGameItem> get allInputs;

  /// Represents IO as a set of ratios,
  /// The value closest to 0 will be set to 1 or -1 respectively
  /// depending upon whether it's an input or output
  ///
  /// Calculating this must be done independently of [calculate]
  /// If this is not possible, then the value will be null
  ItemIo? get netIoRatios;

  /// [inputConstraints] and [outputConstraints] are given in items per minute
  T calculate({ItemIo inputConstraints, ItemIo outputConstraints});

  void verifyConstraintsAndIo(
    ItemIo inputConstraints,
    ItemIo outputConstraints,
  ) {
    inputConstraints.forEach((input, constraint) {
      if (constraint <= 0) {
        throw ProductionLineException(
          'Input constraint $input had value $constraint',
        );
      } else if (!allInputs.contains(input)) {
        throw ProductionLineException(
          'Input constraint $input is not a valid input',
        );
      }
    });

    outputConstraints.forEach((output, constraint) {
      if (constraint <= 0) {
        throw ProductionLineException(
          'Output constraint $output had value $constraint',
        );
      } else if (!allInputs.contains(output)) {
        throw ProductionLineException(
          'Output constraint $output is not a valid input',
        );
      }
    });
  }

  @override
  String toString() => name;
}

/// Represents a line output given a set of constraints
///
/// Only the displayData should be displayed to an end user
/// All other fiels, both here and in inherited classes,
/// exists for utility reasons - to be used in further equations / operations
abstract class ProductionLineIoData {
  /// DisplayData for end user
  /// No data in here should be used for math or further operations
  /// If any useful data exists, it should be made it's own field
  final List<DisplayData> displayData;

  /// Given in items per minute
  final ItemIo netOutput;

  /// Given in items per minute
  final ItemIo netInput;

  final ItemIo inputConstraints;
  final ItemIo outputConstraints;

  final double electricPowerConsumption;

  /// Given in pollution per minute
  final Map<String, double> pollution;

  ProductionLineIoData({
    required List<DisplayData> displayData,
    required ItemIo netOutput,
    required ItemIo netInput,
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
    this.electricPowerConsumption = 0,
    Map<String, double> pollution = const {},
  }) : displayData = List.unmodifiable(displayData),
       netInput = Map.unmodifiable(netInput),
       netOutput = Map.unmodifiable(netOutput),
       inputConstraints = Map.unmodifiable(inputConstraints),
       outputConstraints = Map.unmodifiable(outputConstraints),
       pollution = Map.unmodifiable(pollution);
}

class ProductionLineException extends FactorioException {
  ProductionLineException(super.message);

  @override
  String toString() => 'ProductionLineException: $message';
}
