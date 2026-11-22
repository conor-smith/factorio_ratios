part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final DDItemGroup _internalPrototype;

  List<ItemSubgroup> get subgroups => _database.getGroupSubgroups(this);

  ItemGroup({required this._internalPrototype, required super.database})
    : super(icon: _internalPrototype.icon);
}
