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
    required SolidItemJson super.internalPrototype,
    required super.quality,
  }) : _internalPrototype = internalPrototype {
    _database._solidItems.update(
      name,
      (qualityMap) => qualityMap..[quality] = this,
      ifAbsent: () => {quality: this},
    );
  }
}

class Fluid extends PrototypeWithIcon implements Item {
  @override
  final FluidJson _internalPrototype;

  Fluid({required super.database, required FluidJson super.internalPrototype})
    : _internalPrototype = internalPrototype {
    _database._fluids[name] = this;
  }
}
