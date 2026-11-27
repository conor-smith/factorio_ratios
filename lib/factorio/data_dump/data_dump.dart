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

abstract class PrototypeJson extends AbstractPrototype {
  static const _defaultOrder = '';

  dynamic get localisedName;
  String? get subgroupName;

  @override
  String toString() => name;
}

// Not technically a factorio type, but helpful for this use case
abstract class PrototypeWithIconJson extends PrototypeJson {
  Icon? get icon;
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
