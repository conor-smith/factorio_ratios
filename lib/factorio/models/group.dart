part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final ItemGroupJson _internalPrototype;

  @relationship
  List<ItemSubgroup> get subgroups => throw UnimplementedError();

  ItemGroup({required super.database, required this._internalPrototype});
}
