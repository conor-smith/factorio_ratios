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

abstract class Prototype implements AbstractPrototype, Comparable<Prototype> {
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
  int compareTo(Prototype other) {
    if (other is PrototypeWithQuality) {
      return -other.compareTo(this);
    } else {
      return _compareToNoQuality(other);
    }
  }

  int _compareToNoQuality(Prototype other) {
    var orderVal = order.compareTo(other.order);
    return orderVal != 0 ? orderVal : name.compareTo(other.name);
  }

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

abstract class PrototypeWithQuality<T extends PrototypeWithQuality<T>>
    extends PrototypeWithIcon {
  final Quality quality;
  T withQuality(Quality quality);

  PrototypeWithQuality({required super.database, required this.quality});

  @override
  int compareTo(Prototype other) {
    if (other.internalJson == internalJson && other is PrototypeWithQuality) {
      return switch (quality.compareToQuality(other.quality)) {
        QualityCompare.equalTo ||
        QualityCompare.notInChain => quality.compareTo(other.quality),
        QualityCompare.greaterThan => 1,
        QualityCompare.lessThan => -1,
      };
    } else {
      return _compareToNoQuality(other);
    }
  }

  @override
  String toString() => '$quality $name';
}
