part of '../models.dart';

class ItemGroup extends Ordered implements HasIcon {
  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  final List<IconData>? icons;

  ItemGroup._({
    required this.factorioDb,
    required this.name,
    required this.order,
    required this.icons,
  });

  factory ItemGroup.fromJson(FactorioDatabase factorioDb, Map json) =>
      ItemGroup._(
        factorioDb: factorioDb,
        name: json['name'],
        order: json['order'],
        icons: IconData.fromTopLevelJson(json),
      );
}
