part of 'models.dart';

class ItemSubgroup extends Prototype {
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

  final String _groupString;

  late final ItemGroup group = factorioDb.itemGroupMap[_groupString]!;

  ItemSubgroup._({
    required this.factorioDb,
    required this.name,
    required this.type,
    required this.localisedName,
    required String group,
    required this.order,
  }) : _groupString = group;

  factory ItemSubgroup.fromJson(FactorioDatabase factorioDb, Map json) =>
      ItemSubgroup._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        localisedName: json['name'],
        group: json['group'],
        order: json['order'],
      );
}
