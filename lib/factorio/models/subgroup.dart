part of '../models.dart';

class ItemSubgroup extends Ordered {
  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;

  final String _groupString;

  late final ItemGroup group = factorioDb.itemGroupMap[_groupString]!;

  ItemSubgroup._({
    required this.factorioDb,
    required this.name,
    required String group,
    required this.order,
  }) : _groupString = group;

  factory ItemSubgroup.fromJson(FactorioDatabase factorioDb, Map json) =>
      ItemSubgroup._(
        factorioDb: factorioDb,
        name: json['name'],
        group: json['group'],
        order: json['order'],
      );
}
