part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final ItemGroupJson _internalJson;

  late final List<ItemSubgroup> subgroups = _getSubgroups();

  ItemGroup({required super.database, required this._internalJson});

  @override
  ItemSubgroup? _getSubgroup() => null;

  List<ItemSubgroup> _getSubgroups() => List.unmodifiableOf(
    _database._subgroups.values
        .where((subgroup) => subgroup.group == this)
        .toList(growable: false)
      ..sort(),
  );
}
