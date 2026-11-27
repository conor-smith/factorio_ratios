part of 'models.dart';

class ItemSubgroup with BasicPrototype implements Prototype {
  @override
  final FactorioDatabase _database;
  @override
  final ItemSubgroupJson _internalPrototype;

  @override
  ItemSubgroup? get subgroup => null;
  @override
  String get localName => name;
  @override
  String get name => _internalPrototype.name;
  @override
  String get type => _internalPrototype.type;
  @override
  String get order => _internalPrototype.order;

  // TODO - Handle potential missing groups
  late final ItemGroup group = _database._groups[_internalPrototype.group]!;

  ItemSubgroup({required this._internalPrototype, required this._database});
}
