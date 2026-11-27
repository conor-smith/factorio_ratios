part of 'models.dart';

class ItemGroup with BasicPrototype implements PrototypeWithIcon {
  @override
  final FactorioDatabase _database;
  @override
  final ItemGroupJson _internalPrototype;

  @override
  late final String localName = _getLocalName(
    _database,
    name,
    _internalPrototype.localisedName,
  );

  @override
  late final Icon icon = throw UnimplementedError();
  late final List<ItemSubgroup> subgroups = List.unmodifiable(
    _database._subgroups.values.where((subgroup) => subgroup.group == this),
  );

  @override
  String get name => _internalPrototype.name;
  @override
  String get type => _internalPrototype.type;
  @override
  String get order => _internalPrototype.order;

  @override
  ItemSubgroup? get subgroup => null;

  ItemGroup({required this._database, required this._internalPrototype});
}
