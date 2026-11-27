part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final ItemGroupJson _internalPrototype;

  List<ItemSubgroup> get subgroups => _database.getGroupSubgroups(this);

  ItemGroup({
    required super.database,
    required ItemGroupJson super.internalPrototype,
  }) : _internalPrototype = internalPrototype,
       super(expectedIconSize: ExpectedIconSize.itemGroup) {
    _database._groups[name] = this;
  }
}
