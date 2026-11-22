part of 'models.dart';

class FactorioDatabase {
  final Map<String, ItemSubgroup> _subgroups = {};
}

class _DbIconCache {}

class _IconCacheKey {
  final Icon? icon;
  final double iconSize;
  final Quality quality;
}
