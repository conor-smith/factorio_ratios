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
