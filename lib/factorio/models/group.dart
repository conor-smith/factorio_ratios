part of '../models.dart';

class ItemGroup extends Ordered implements HasIcon {
  static const double _expectedIconSize = 128;
  static const double _defaultScale =
      (_expectedIconSize / 2) / _expectedIconSize;

  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  final List<IconData>? icons;
  @override
  double get expectedIconSize => _expectedIconSize;
  @override
  double get defaultScale => _defaultScale / 2;

  ItemGroup._({
    required this.factorioDb,
    required this.name,
    required this.order,
    required this.icons,
  });

  factory ItemGroup.fromJson(FactorioDatabase factorioDb, Map json) =>
      ItemGroup._(
        factorioDb: factorioDb,
        name: json['name'],
        order: json['order'],
        icons: IconData.fromTopLevelJson(json, ItemGroup._expectedIconSize),
      );
}
