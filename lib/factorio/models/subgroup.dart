part of 'models.dart';

class ItemSubgroup
    with PrototypeDelegator, BasicPrototype
    implements Prototype {
  @override
  final FactorioDatabase _database;
  @override
  final ItemSubgroupJson _internalPrototype;

  @override
  ItemSubgroup? get subgroup => null;

  // TODO - Handle potential missing groups
  late final ItemGroup group = _database._groups[_internalPrototype.group]!;

  ItemSubgroup({required this._internalPrototype, required this._database});
}
