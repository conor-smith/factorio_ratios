part of 'models.dart';

class FactorioDatabase {
  // All objects with quality are indexed as name -> quality name -> object
  final Map<String, Map<String, CraftingMachine>> _craftingMachines = {};
  final Map<String, ItemGroup> _groups = {};
  final Map<String, Map<String, SolidItem>> _items = {};
  final Map<String, Fluid> _fluids = {};
  final Map<String, Quality> _qualities = {};
  final Map<String, Map<String, Recipe>> _recipes = {};
  final Map<String, ItemSubgroup> _subgroups = {};
  final Map<String, Surface> _surfaces = {};

  static const normalQualityName = 'normal';
  late final Quality normalQuality;
}
