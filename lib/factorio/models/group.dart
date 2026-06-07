part of 'models.dart';

class ItemGroup extends Prototype {
  static const double _expectedIconSize = 128;
  static const double _defaultScale =
      (_expectedIconSize / 2) / _expectedIconSize;

  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String type;
  @override
  final String localisedName;
  @override
  final String order;

  @override
  ItemSubgroup? get subgroup => null;

  final List<IconData>? icons;
  double get expectedIconSize => _expectedIconSize;
  double get defaultScale => _defaultScale / 2;

  ItemGroup._({
    required this.factorioDb,
    required this.name,
    required this.type,
    required this.localisedName,
    required this.order,
    required this.icons,
  });

  factory ItemGroup.fromJson(FactorioDatabase factorioDb, Map json) =>
      ItemGroup._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        order: json['order'],
        localisedName: json['name'],
        icons: IconData.fromTopLevelJson(json, ItemGroup._expectedIconSize),
      );
}
