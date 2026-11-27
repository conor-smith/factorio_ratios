part of 'models.dart';

abstract class Item implements PrototypeWithIcon {
  @override
  ItemJson get internalJson;
}

class SolidItem extends PrototypeWithQuality<SolidItem> implements Item {
  @override
  final SolidItemJson internalJson;

  SolidItem({
    required super.database,
    required super.quality,
    required this.internalJson,
  });

  @override
  SolidItem withQuality(Quality quality) => throw UnimplementedError(); // TODO
}

class Fluid extends PrototypeWithIcon implements Item {
  @override
  final FluidJson internalJson;

  Fluid({required super.database, required this.internalJson});
}
