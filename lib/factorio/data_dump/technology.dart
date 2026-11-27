part of 'data_dump.dart';

class TechnologyJson extends PrototypeWithIconJson {
  final List<Modifier>? effects;

  TechnologyJson._({
    required super.name,
    required super.type,
    required super.order,
    required super.localisedName,
    required super.subgroupName,
    required super.icon,
    required Iterable<Modifier>? effects,
  }) : effects = _unmodifiableOrNullList(effects),
       super._();

  factory TechnologyJson.fromJson(Map json) {
    List? rawModifiers = json['modifiers'];
    var modifiers = rawModifiers?.map(
      (modifierJson) => Modifier.fromJson(modifierJson),
    );

    return TechnologyJson._(
      name: json['name'],
      type: json['type'],
      order: json['order'],
      subgroupName: json['subgroup'],
      localisedName: json['localised_name'],
      icon: Icon.fromTopLevelJson(json, ExpectedIconSize.technology),
      effects: modifiers,
    );
  }
}

class Modifier {
  final String type;
  final String? recipe;

  Modifier.fromJson(Map json) : type = json['type']!, recipe = json['recipe'];
}
