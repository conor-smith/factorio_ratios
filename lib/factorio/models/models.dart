import 'package:factorio_ratios/factorio/data_dump/data_dump.dart';
import 'package:factorio_ratios/factorio/factorio.dart';

part 'database.dart';
part 'group.dart';
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

  @override
  String get localName => name; // TODO

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
    required Icon? icon,
    double expectedIconSize = ExpectedIconSize.other,
  })
}

abstract class PrototypeWithQuality extends PrototypeWithIcon {
  final Quality quality;

  PrototypeWithQuality({
    required super.database,
    required super.icon,
    required this.quality,
  });

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
