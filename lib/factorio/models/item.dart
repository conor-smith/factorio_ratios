part of 'models.dart';

abstract class Item implements PrototypeWithIcon {
  @override
  DDItem get _internalPrototype;
}

class SolidItem extends PrototypeWithQuality implements Item {
  @override
  final DDSolidItem _internalPrototype;

  SolidItem({
    required super.database,
    required DDSolidItem super.internalPrototype,
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
  final DDFluid _internalPrototype;

  Fluid({required super.database, required DDFluid super.internalPrototype})
    : _internalPrototype = internalPrototype {
    _database._fluids[name] = this;
  }
}
