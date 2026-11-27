import 'package:factorio_ratios/factorio/data_dump/data_dump.dart';
import 'package:factorio_ratios/factorio/factorio.dart';

part 'database.dart';
part 'group.dart';
part 'item.dart';
part 'quality.dart';
part 'subgroup.dart';

class _Relationship {
  const _Relationship();
}

const relationship = _Relationship();

abstract class Prototype extends AbstractPrototype
    implements Comparable<Prototype> {
  PrototypeJson get _internalPrototype;

  final FactorioDatabase _database;

  @override
  String get name => _internalPrototype.name;
  @override
  String get type => _internalPrototype.type;
  @override
  String get order => _internalPrototype.order;

  String get localName => name; // TODO

  @relationship
  late final ItemSubgroup? subgroup = _getSubgroup();

  Prototype({required this._database});

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

  ItemSubgroup? _getSubgroup() =>
      _database._subgroups[_internalPrototype.subgroupName];

  @override
  String toString() => name;
}

abstract class PrototypeWithIcon extends Prototype {
  @override
  PrototypeWithIconJson get _internalPrototype;

  @relationship
  late final Icon icon = _getIcon(expectedIconSize);
  double get expectedIconSize => ExpectedIconSize.other;

  PrototypeWithIcon({required super.database});

  Icon _getIcon(double expectedIconSize) => _database.cacheAndRetrieveIcon(
    icon: _internalPrototype.icon,
    expectedIconSize: expectedIconSize,
  );
}

abstract class PrototypeWithQuality extends PrototypeWithIcon {
  final String _qualityName;

  @relationship
  late final Quality quality = _database._qualities[_qualityName]!;

  PrototypeWithQuality({required super.database, required this._qualityName});

  @override
  int compareTo(Prototype other) {
    if (other._internalPrototype == _internalPrototype &&
        other is PrototypeWithQuality) {
      return switch (quality.compareToQuality(other.quality)) {
        QualityCompare.equalTo ||
        QualityCompare.notInChain => quality.compareTo(other.quality),
        QualityCompare.greaterThan => 1,
        QualityCompare.lessThan => -1,
      };
    } else {
      return super._compareToNoQuality(other);
    }
  }

  @override
  Icon _getIcon(double expectedIconSize) => _database.cacheAndRetrieveIcon(
    icon: _internalPrototype.icon,
    expectedIconSize: expectedIconSize,
    quality: quality,
  );

  @override
  String toString() => '${quality.name} ${_internalPrototype.name}';
}
