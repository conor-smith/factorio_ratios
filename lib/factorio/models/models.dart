import 'package:factorio_ratios/factorio/data_dump/data_dump.dart';
import 'package:factorio_ratios/factorio/factorio.dart';

part 'database.dart';
part 'group.dart';
part 'item.dart';
part 'quality.dart';
part 'subgroup.dart';

abstract class Prototype extends AbstractPrototype
    implements Comparable<Prototype> {
  DDPrototype get _internalPrototype;

  final FactorioDatabase _database;

  @override
  String get name => _internalPrototype.name;
  @override
  String get type => _internalPrototype.type;
  @override
  String get order => _internalPrototype.order;

  String get localName => name; // TODO

  ItemSubgroup? get subgroup =>
      _database._subgroups[_internalPrototype.subgroupName];

  Prototype({required this._database});

  @override
  int compareTo(Prototype other) {
    var orderVal = order.compareTo(other.order);
    return orderVal != 0 ? orderVal : name.compareTo(other.name);
  }
}

abstract class PrototypeWithIcon extends Prototype {
  @override
  DDPrototypeWithIcon get _internalPrototype;

  final Icon icon;

  PrototypeWithIcon({
    required super.database,
    required DDPrototypeWithIcon internalPrototype,
    double expectedIconSize = ExpectedIconSize.other,
    Quality? quality,
  }) : icon = database.cacheAndRetrieveIcon(
         icon: internalPrototype.icon,
         expectedIconSize: expectedIconSize,
         quality: quality,
       );
}

abstract class PrototypeWithQuality extends PrototypeWithIcon {
  final Quality quality;

  PrototypeWithQuality({
    required super.database,
    required super.internalPrototype,
    required Quality super.quality,
    super.expectedIconSize,
  }) : quality = quality;

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
      return super.compareTo(other);
    }
  }

  @override
  String toString() => '${quality.name} ${_internalPrototype.name}';
}
