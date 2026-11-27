part of 'models.dart';

class ItemGroup
    with PrototypeDelegator, BasicPrototype
    implements PrototypeWithIcon {
  @override
  final FactorioDatabase _database;
  @override
  final ItemGroupJson _internalPrototype;

  @override
  ItemSubgroup? get subgroup => null;
  @override
  double get expectedIconSize => ExpectedIconSize.itemGroup;

  @override
  late final Icon icon = _database.cacheAndRetrieveIcon(
    icon: icon,
    expectedIconSize: expectedIconSize,
  );
  late final List<ItemSubgroup> subgroups = List.unmodifiable(
    _database._subgroups.values.where((subgroup) => subgroup.group == this),
  );

  ItemGroup({required this._database, required this._internalPrototype});
}
