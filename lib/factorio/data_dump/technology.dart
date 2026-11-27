part of 'data_dump.dart';

class TechnologyJson extends PrototypeWithIconJson {
  @override
  final String name;
  @override
  final String type;
  @override
  final String order;
  @override
  final String? subgroupName;
  @override
  final dynamic localisedName;
  @override
  final Icon? icon;

  final List<Modifier>? effects;

  TechnologyJson._({
    required this.name,
    required this.type,
    required String? order,
    required this.subgroupName,
    required dynamic localisedName,
    required this.icon,
    required Iterable<Modifier>? effects,
  }) : order = order ?? PrototypeJson._defaultOrder,
       localisedName = _unmodifiableLocalisedString(localisedName),
       effects = _unmodifiableOrNullList(effects);

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
