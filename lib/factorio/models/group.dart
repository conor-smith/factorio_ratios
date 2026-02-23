part of '../models.dart';

class ItemGroup extends Ordered {
  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;

  final String icon;

  ItemGroup._({
    required this.factorioDb,
    required this.name,
    required this.order,
    required this.icon,
  });

  factory ItemGroup.fromJson(FactorioDatabase factorioDb, Map json) =>
      ItemGroup._(
        factorioDb: factorioDb,
        name: json['name'],
        order: json['order'],
        icon: json['icon'],
      );
}
