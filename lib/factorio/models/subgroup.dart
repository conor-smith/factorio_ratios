part of 'models.dart';

class ItemSubgroup extends Prototype {
  @override
  final DDItemSubgroup _internalPrototype;

  // TODO - Handle potential missing groups
  ItemGroup get group => _database._groups[_internalPrototype.group]!;

  ItemSubgroup({required this._internalPrototype, required super.database}) {
    _database._subgroups[_internalPrototype.name] = this;
  }
}
