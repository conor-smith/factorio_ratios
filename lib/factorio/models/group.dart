part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final ItemGroupJson _internalJson;

  late final List<ItemSubgroup> subgroups = List.unmodifiableOf(
    _database._subgroups.values
        .where((subgroup) => subgroup.group == this)
        .toList(growable: false)
      ..sort(),
  );

  ItemGroup({required super.database, required this._internalJson});

  @override
  ItemSubgroup? _getSubgroup() => null;
}
