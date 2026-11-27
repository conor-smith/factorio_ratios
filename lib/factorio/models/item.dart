part of 'models.dart';

abstract class Item implements PrototypeWithIcon {
  @override
  ItemJson get _internalPrototype;
}

class SolidItem extends PrototypeWithQuality implements Item {
  @override
  final SolidItemJson _internalPrototype;

  SolidItem({
    required super.database,
    required super.qualityName,
    required this._internalPrototype,
  });
}

class Fluid extends PrototypeWithIcon implements Item {
  @override
  final FluidJson _internalPrototype;

  Fluid({required super.database, required this._internalPrototype});
}
