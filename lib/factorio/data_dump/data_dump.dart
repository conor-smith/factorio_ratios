import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'crafting_machines.dart';
part 'database.dart';
part 'group.dart';
part 'icon.dart';
part 'item.dart';
part 'quality.dart';
part 'recipe.dart';
part 'subgroup.dart';
part 'surface.dart';
part 'technology.dart';

abstract class DDPrototype extends TPrototype {
  @override
  final String name;
  @override
  final String type;
  final dynamic localisedName;
  @override
  final String order;
  final String? subgroupName;

  DDPrototype({
    required this.name,
    required this.type,
    required this.localisedName,
    required String? order,
    required this.subgroupName,
  }) : order = order ?? '';

  DDPrototype.fromJson(Map json)
    : this(
        name: json['name'],
        type: json['type'],
        localisedName: _unmodifiableLocalisedString(json['localised_name']),
        order: json['order'],
        subgroupName: json['subgroup'],
      );

  @override
  String toString() => name;
}

// Not technically a factorio type, but helpful for this use case
abstract class DDPrototypeWithIcon extends DDPrototype {
  final Icon? icon;

  DDPrototypeWithIcon.fromJson(super.json, double expectedIconSize)
    : icon = Icon.fromTopLevelJson(json, expectedIconSize),
      super.fromJson();
}

class SpentFluidSpecification {
  final String name;
  final double amount;
  final double temperature;

  SpentFluidSpecification._({
    required this.name,
    required double? amount,
    required double? temperature,
  }) : amount = amount ?? 1,
       temperature = temperature ?? 0;

  factory SpentFluidSpecification.fromJson(Map json) =>
      SpentFluidSpecification._(
        name: json['name'],
        amount: json['amount']?.toDouble(),
        temperature: json['temperature']?.toDouble(),
      );
}

enum Effects {
  consumption('consumption', minMultiplier: 0.2),
  productivity('productivity', minMultiplier: 1),
  speed('speed', minMultiplier: 0.2),
  pollution('pollution'),
  quality('quality', defaultMultiplier: 0);

  final String name;
  final double defaultMultiplier;

  final double minMultiplier;
  final double maxMultiplier;

  final double minBonus;
  final double maxBonus;

  const Effects(
    this.name, {
    this.defaultMultiplier = 1,
    this.minMultiplier = double.negativeInfinity,
    this.maxMultiplier = double.infinity,
  }) : minBonus = minMultiplier - defaultMultiplier,
       maxBonus = maxMultiplier - defaultMultiplier;

  double bonusOrBound(double bonus) {
    if (bonus > maxBonus) {
      return maxBonus;
    } else if (bonus < minBonus) {
      return minBonus;
    } else {
      return bonus;
    }
  }

  @override
  String toString() => name;
}

List<T>? _unmodifiableOrNullList<T>(Iterable<T>? list) =>
    list != null ? List.unmodifiableOf(list) : null;

Map<K, V>? _unmodifiableOrNullMap<K, V>(Map<K, V>? map) =>
    map != null ? Map.unmodifiableOf(map) : null;

Map<String, double>? _parseStringDoubleMap(Map? map) =>
    map?.map((key, value) => MapEntry(key, value.toDouble()));

// LocalisedString can be null, String, or List<dynamic>
// Lists may contain Strings, or lists
// This function recursively makes all internal lists unmodifiable
dynamic _unmodifiableLocalisedString(dynamic localisedString) {
  if (localisedString is List) {
    localisedString = List.unmodifiable(
      localisedString.map(_unmodifiableLocalisedString),
    );
  }

  return localisedString;
}
