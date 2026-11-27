import 'package:factorio_ratios/factorio/data_dump/data_dump.dart';
import 'package:factorio_ratios/factorio/factorio.dart';

part 'database.dart';
part 'group.dart';
part 'item.dart';
part 'quality.dart';
part 'subgroup.dart';

abstract class Prototype extends AbstractPrototype
    implements Comparable<Prototype> {
  PrototypeJson get _internalPrototype;
  FactorioDatabase get _database;
  ItemSubgroup? get subgroup;

  String get localName;
}

mixin BasicPrototype implements Prototype {
  @override
  int compareTo(Prototype other) {
    if (other is PrototypeWithQuality) {
      return -other.compareTo(this);
    } else {
      var orderVal = order.compareTo(other.order);
      return orderVal != 0 ? orderVal : name.compareTo(other.name);
    }
  }

  @override
  String toString() => name;
}

abstract class PrototypeWithIcon implements Prototype {
  @override
  PrototypeWithIconJson get _internalPrototype;

  Icon get icon;
}

abstract class PrototypeWithQuality implements PrototypeWithIcon {
  String get _qualityName;
  Quality get quality;

  @override
  String toString() => '${quality.name} ${_internalPrototype.name}';
}

mixin BasicPrototypeWithQuality implements PrototypeWithQuality {
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
      var orderVal = order.compareTo(other.order);
      return orderVal != 0 ? orderVal : name.compareTo(other.name);
    }
  }

  @override
  String toString() => '${quality.name} $name';
}

ItemSubgroup? _getSubgroup(
  FactorioDatabase database,
  PrototypeJson prototypeJson,
) => database._subgroups[prototypeJson.subgroupName];

String _getLocalName(
  FactorioDatabase database,
  String name,
  dynamic localisedName,
) => name; // TODO

Quality _getQuality(FactorioDatabase database, String qualityName) =>
    database._qualities[qualityName]!;
