part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final DDItemGroup _internalPrototype;

  List<ItemSubgroup> get subgroups => _database.getGroupSubgroups(this);

  ItemGroup({
    required super.database,
    required DDItemGroup super.internalPrototype,
  }) : _internalPrototype = internalPrototype {
    _database._groups[name] = this;
  }
}
