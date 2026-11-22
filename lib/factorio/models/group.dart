part of 'models.dart';

class ItemGroup extends PrototypeWithIcon {
  @override
  final DDItemGroup _internalPrototype;

  ItemGroup({required this._internalPrototype, required super.database})
    : super(icon: _internalPrototype.icon);
}
