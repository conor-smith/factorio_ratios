part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
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

  @override
  final Icon? icon;

  ItemGroup._({
    required this.factorioDb,
    required this.name,
    required this.type,
    required this.localisedName,
    required this.order,
    required this.icon,
  });

  factory ItemGroup.fromJson(FactorioDatabase factorioDb, Map json) =>
      ItemGroup._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        order: json['order'],
        localisedName: json['name'],
        icon: Icon.fromTopLevelJson(json, ExpectedIconSize.itemGroup),
      );
}
