part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final ItemGroupJson _internalPrototype;

  @relationship
  late final List<ItemSubgroup> subgroups = List.unmodifiable(
    _database._subgroups.values.where((subgroup) => subgroup.group == this),
  );

  ItemGroup({required super.database, required this._internalPrototype});
}
