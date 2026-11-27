part of 'models.dart';

abstract class Item implements PrototypeWithIcon {
  @override
  ItemJson get _internalPrototype;
}

class SolidItem
    with PrototypeDelegator, BasicPrototypeWithQuality
    implements PrototypeWithQuality, Item {
  @override
  final FactorioDatabase _database;
  @override
  final SolidItemJson _internalPrototype;
  @override
  final String _qualityName;

  @override
  late final ItemSubgroup? subgroup = _getSubgroup();
  @override
  late final Icon icon = _getIcon();

  @override
  late final Quality quality = _getQuality();

  SolidItem({
    required this._database,
    required this._qualityName,
    required this._internalPrototype,
  });
}

class Fluid
    with PrototypeDelegator, BasicPrototype
    implements PrototypeWithIcon, Item {
  @override
  final FactorioDatabase _database;
  @override
  final FluidJson _internalPrototype;

  @override
  late final ItemSubgroup? subgroup = _getSubgroup();
  @override
  late final Icon icon = _database.cacheAndRetrieveIcon(
    icon: _internalPrototype.icon,
    expectedIconSize: expectedIconSize,
  );

  @override
  double get expectedIconSize => ExpectedIconSize.other;

  Fluid({required this._database, required this._internalPrototype});
}
