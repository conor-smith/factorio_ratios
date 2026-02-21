part of '../models.dart';

class ItemGroup {
  final FactorioDatabase factorioDb;

  final String name;
  final String order;
  final String icon;

  late final List<ItemSubgroup> subgroups = UnmodifiableListView(
    factorioDb._groupToSubGroup[this] ?? const [],
  );

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
