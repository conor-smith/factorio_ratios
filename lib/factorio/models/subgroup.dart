part of '../models.dart';

class ItemSubgroup {
  final FactorioDatabase factorioDb;

  final String name;
  final String _groupString;
  final String order;

  late final ItemGroup group = factorioDb.itemGroupMap[_groupString]!;
  late final List<Item> items = UnmodifiableListView(
    factorioDb._subgroupToItems[this] ?? const [],
  );
  late final List<Recipe> recipes = UnmodifiableListView(
    factorioDb._subgroupToRecipes[this] ?? const [],
  );

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
