part of 'models.dart';

class ItemSubgroup extends Prototype {
  @override
  final ItemSubgroupJson _internalPrototype;

  // TODO - Handle potential missing groups
  @relationship
  late final ItemGroup group = _database._groups[_internalPrototype.group]!;

  ItemSubgroup({required this._internalPrototype, required super.database}) {
    _database._subgroups[_internalPrototype.name] = this;
  }
}
