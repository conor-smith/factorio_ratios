part of 'models.dart';

class ItemSubgroup extends Prototype {
  @override
  final ItemSubgroupJson _internalJson;

  late final ItemGroup group = _database._groups[_internalJson.group]!;

  ItemSubgroup({required super.database, required this._internalJson});

  @override
  ItemSubgroup? _getSubgroup() => null;
}
