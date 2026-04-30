import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';

part 'magic_line.dart';
part 'single_recipe.dart';

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
abstract mixin class ProductionLine<T extends ProductionLineIo> {
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
  T calculate(ItemIo inputConstraints, ItemIo outputConstraints);

  void verifyConstraintsAndIo({
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
  }) {
    inputConstraints.forEach((input, constraint) {
      if (constraint <= 0) {
        throw ProductionLineException(
          this,
          'Input constraint $input had value $constraint',
        );
      } else if (!allInputs.contains(input)) {
        throw ProductionLineException(
          this,
          'Input constraint $input is not a valid input',
        );
      }
    });

    outputConstraints.forEach((output, constraint) {
      if (constraint <= 0) {
        throw ProductionLineException(
          this,
          'Output constraint $output had value $constraint',
        );
      } else if (!allInputs.contains(output)) {
        throw ProductionLineException(
          this,
          'Output constraint $output is not a valid input',
        );
      }
    });
  }

  @override
  String toString() => name;
}

abstract class ProductionLineIo {
  /// Given in items per minute
  final ItemIo netIo;

  final ItemIo inputConstraints;
  final ItemIo outputConstraints;

  final double electricPowerConsumption;

  /// Given in pollution per minute
  final Map<String, double> pollution;

  ProductionLineIo({
    required this.netIo,
    this.inputConstraints = const {},
    this.outputConstraints = const {},
    this.electricPowerConsumption = 0,
    this.pollution = const {},
  });
}

class ProductionLineException extends FactorioException {
  final ProductionLine source;

  ProductionLineException(this.source, super.message);

  @override
  String toString() => 'ProductionLineException: $message';
}
