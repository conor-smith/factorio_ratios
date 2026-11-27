part of 'models.dart';

abstract class Item implements PrototypeWithIcon {
  @override
  ItemJson get _internalPrototype;
}

class SolidItem
    with BasicPrototypeWithQuality
    implements PrototypeWithQuality, Item {
  @override
  final FactorioDatabase _database;
  @override
  final SolidItemJson _internalPrototype;
  @override
  final String _qualityName;

  @override
  late final String localName = _getLocalName(
    _database,
    name,
    _internalPrototype.localisedName,
  );
  @override
  late final ItemSubgroup? subgroup = _getSubgroup(
    _database,
    _internalPrototype,
  );
  @override
  late final Icon icon = throw UnimplementedError(); // TODO

  @override
  late final Quality quality = _getQuality(_database, _qualityName);

  @override
  String get name => _internalPrototype.name;
  @override
  String get type => _internalPrototype.type;
  @override
  String get order => _internalPrototype.order;

  SolidItem({
    required this._database,
    required this._qualityName,
    required this._internalPrototype,
  });
}

class Fluid with BasicPrototype implements PrototypeWithIcon, Item {
  @override
  final FactorioDatabase _database;
  @override
  final FluidJson _internalPrototype;

  @override
  late final String localName = _getLocalName(
    _database,
    name,
    _internalPrototype.localisedName,
  );
  @override
  late final ItemSubgroup? subgroup = _getSubgroup(
    _database,
    _internalPrototype,
  );
  @override
  late final Icon icon = throw UnimplementedError(); // TODO

  @override
  String get name => _internalPrototype.name;
  @override
  String get type => _internalPrototype.type;
  @override
  String get order => _internalPrototype.order;

  Fluid({required this._database, required this._internalPrototype});
}
