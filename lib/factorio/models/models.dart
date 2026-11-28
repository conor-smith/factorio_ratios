import 'package:factorio_ratios/factorio/data_dump/data_dump.dart';
import 'package:factorio_ratios/factorio/factorio.dart';

part 'crafting_machine.dart';
part 'database.dart';
part 'group.dart';
part 'item.dart';
part 'quality.dart';
part 'recipe.dart';
part 'subgroup.dart';
part 'surface.dart';

const Map<String, double> _multipliers = {
  "k": 1.0e3,
  "M": 1.0e6,
  "G": 1.0e9,
  "T": 1.0e12,
  "P": 1.0e15,
  "E": 1.0e18,
  "Z": 1.0e21,
  "Y": 1.0e24,
  "R": 1.0e27,
  "Q": 1.0e30,
};

abstract class Prototype implements AbstractPrototype {
  final FactorioDatabase _database;

  PrototypeJson get internalJson;

  @override
  String get name => internalJson.name;
  @override
  String get type => internalJson.type;
  @override
  String get order => internalJson.order;

  late final ItemSubgroup? subgroup = _getSubgroup();

  Prototype({required this._database});

  ItemSubgroup? _getSubgroup() =>
      _database._subgroups[internalJson.subgroupName];

  @override
  String toString() => name;
}

abstract class PrototypeWithIcon extends Prototype {
  @override
  PrototypeWithIconJson get internalJson;

  late final Icon? icon = _getIcon();

  PrototypeWithIcon({required super.database});

  Icon? _getIcon() => internalJson.icon;
}

double _convertStringToEnergy(String energyUsage) {
  String multiplier = energyUsage.substring(
    energyUsage.length - 2,
    energyUsage.length - 1,
  );

  if (_multipliers.containsKey(multiplier)) {
    return double.parse(energyUsage.substring(0, energyUsage.length - 2)) *
        _multipliers[multiplier]!;
  } else {
    return double.parse(energyUsage.substring(0, energyUsage.length - 1));
  }
}
