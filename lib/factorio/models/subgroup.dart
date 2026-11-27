part of 'models.dart';

class ItemSubgroup extends Prototype {
  @override
  final ItemSubgroupJson internalJson;

  late final ItemGroup group = _database._groups[internalJson.group]!;

  ItemSubgroup({required super.database, required this.internalJson});

  @override
  ItemSubgroup? _getSubgroup() => null;
}
