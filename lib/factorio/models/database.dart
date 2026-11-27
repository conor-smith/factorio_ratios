part of 'models.dart';

class FactorioDatabase {
  final Map<String, ItemSubgroup> _subgroups = {};
  final Map<String, Quality> _qualities = {};
  final Map<String, ItemGroup> _groups = {};

  Icon _getIcon({
    required Icon? icon,
    required double expectedSize,
    Quality? quality,
  }) => throw UnimplementedError();
}
