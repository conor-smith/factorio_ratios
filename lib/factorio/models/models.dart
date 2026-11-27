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

  PrototypeJson get _internalJson;

  @override
  String get name => _internalJson.name;
  @override
  String get type => _internalJson.type;
  @override
  String get order => _internalJson.order;

  late final ItemSubgroup? subgroup = _getSubgroup();

  Prototype({required this._database});

  ItemSubgroup? _getSubgroup() =>
      _database._subgroups[_internalJson.subgroupName];

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
  PrototypeWithIconJson get _internalJson;

  late final Icon icon = _getIcon();

  PrototypeWithIcon({required super.database});

  Icon _getIcon() =>
      _database._getIcon(icon: _internalJson.icon, expectedSize: expectedSize);

  double get expectedSize => ExpectedIconSize.other;
}

abstract class PrototypeWithQuality extends PrototypeWithIcon {
  final String _qualityName;

  late final Quality quality = _getQuality();

  PrototypeWithQuality({required super.database, required this._qualityName});

  Quality _getQuality() => _database._qualities[_qualityName]!;

  @override
  Icon _getIcon() => _database._getIcon(
    icon: icon,
    expectedSize: expectedSize,
    quality: quality,
  );

  @override
  int compareTo(Prototype other) {
    if (other._internalJson == _internalJson && other is PrototypeWithQuality) {
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
  String toString() => '$_qualityName $name';
}
