part of 'data_dump.dart';

class DDTechnology extends DDPrototypeWithIcon {
  final List<Modifier>? effects;

  DDTechnology._(Map json, {required Iterable<Modifier>? effects})
    : effects = _unmodifiableOrNullList(effects),
      super.fromJson(json, ExpectedIconSize.technology);

  factory DDTechnology.fromJson(Map json) {
    List? rawModifiers = json['modifiers'];
    var modifiers = rawModifiers?.map(
      (modifierJson) => Modifier.fromJson(modifierJson),
    );

    return DDTechnology._(json, effects: modifiers);
  }
}

class Modifier {
  final String type;
  final String? recipe;

  Modifier.fromJson(Map json) : type = json['type']!, recipe = json['recipe'];
}
