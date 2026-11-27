part of 'models.dart';

abstract class Item implements PrototypeWithIcon {
  @override
  ItemJson get internalJson;
}

class SolidItem extends PrototypeWithQuality implements Item {
  @override
  final SolidItemJson internalJson;

  SolidItem({
    required super.database,
    required super.qualityName,
    required this.internalJson,
  });
}

class Fluid extends PrototypeWithIcon implements Item {
  @override
  final FluidJson internalJson;

  Fluid({required super.database, required this.internalJson});
}
