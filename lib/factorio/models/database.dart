part of 'models.dart';

class FactorioDatabase {
  final Map<String, ItemSubgroup> _subgroups = {};
  final Map<String, ItemGroup> _groups = {};
  final Map<String, Quality> _qualities = {};
  final Map<String, Map<Quality, SolidItem>> _solidItems = {};
  final Map<String, Fluid> _fluids = {};

  final Map<_IconCacheKey, Icon> _iconCache = {};

  final Map<ItemGroup, List<ItemSubgroup>> _cachedSubGroups = {};

  Icon cacheAndRetrieveIcon({
    required Icon? icon,
    required double expectedIconSize,
    Quality? quality,
  }) {
    return _iconCache.putIfAbsent(_IconCacheKey(icon, quality), () {
      // Use default "unknown" icon when icon is absent
      Icon iconToCache =
          icon ??
          Icon([
            IconData(
              icon: '__core__/graphics/icons/unknown.png',
              iconSize: expectedIconSize,
              expectedIconSize: expectedIconSize,
            ),
          ]);

      if (quality?.drawSpriteByDefault == true) {
        iconToCache = Icon([...iconToCache.icons, ...quality!.icon.icons]);
      }

      return iconToCache;
    });
  }

  List<ItemSubgroup> getGroupSubgroups(ItemGroup group) =>
      _cachedSubGroups.putIfAbsent(
        group,
        () => List.unmodifiableOf(
          _subgroups.values
              .where((subgroup) => subgroup.group == group)
              .toList()
            ..sort(),
        ),
      );
}

class _IconCacheKey {
  final Icon? icon;
  final Quality? quality;

  @override
  final int hashCode;

  _IconCacheKey(this.icon, this.quality)
    : hashCode = icon.hashCode + quality.hashCode;

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is _IconCacheKey &&
          icon == other.icon &&
          quality == other.quality);
}
