part of 'models.dart';

class Technology extends PrototypeWithIcon {
  // Only used to determine available recipes for now
  // But this class might be useful later. Best keep it around
  static const double _expectedIconSize = 256,
      _defaultScale = (_expectedIconSize / 2) / _expectedIconSize;

  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  final String type;
  @override
  final String localisedName;
  @override
  late final ItemSubgroup? subgroup =
      factorioDb.itemSubgroupMap[_subgroupString];

  @override
  final Icon? icon;
  @override
  double get expectedIconSize => _expectedIconSize;
  @override
  double get defaultScale => _defaultScale;

  final List<Modifier> effects;

  final String? _subgroupString;

  Technology._({
    required this.factorioDb,
    required this.name,
    required this.order,
    required this.type,
    required this.localisedName,
    required String? subgroup,
    required this.icon,
    required Iterable<Modifier> effects,
  }) : _subgroupString = subgroup,
       effects = List.unmodifiable(effects);

  factory Technology.fromJson(FactorioDatabase factorioDb, Map json) =>
      Technology._(
        factorioDb: factorioDb,
        name: json['name'],
        order: json['order'] ?? '',
        type: json['type'],
        localisedName: json['name'],
        subgroup: json['subgroup'],
        icon: Icon.fromTopLevelJson(json, Item._expectedIconSize),
        effects: (json['effects'] as List? ?? const []).cast<Map>().map(
          (effectJson) => Modifier.fromJson(factorioDb, effectJson),
        ),
      );
}

class Modifier {
  final FactorioDatabase factorioDb;

  final String type;
  final String? _recipeString;

  Modifier.fromJson(this.factorioDb, Map json)
    : type = json['type']!,
      _recipeString = json['recipe'];
}
