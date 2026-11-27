part of 'models.dart';

abstract class Item implements PrototypeWithIcon {
  @override
  ItemJson get _internalJson;
}

class SolidItem extends PrototypeWithQuality implements Item {
  @override
  final SolidItemJson _internalJson;

  SolidItem({
    required super.database,
    required super.qualityName,
    required this._internalJson,
  });
}

class Fluid extends PrototypeWithIcon implements Item {
  @override
  final FluidJson _internalJson;

  Fluid({required super.database, required this._internalJson});
}
