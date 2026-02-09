import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:logging/logging.dart';

part 'production_lines/dynamic_models.dart';
part 'production_lines/multi_line.dart';
part 'production_lines/resource_line.dart';
part 'production_lines/single_recipe.dart';

abstract class ProductionLine {
  void update(Map<ItemData, double> requirements);

  Map<ItemData, double> get ioPerSecond;

  String get name;
}