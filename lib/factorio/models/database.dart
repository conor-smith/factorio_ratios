part of 'models.dart';

class FactorioDatabase {
  final Map<_IconCacheKey, Icon> _iconCache = {};

  final Map<String, ItemSubgroup> _subgroups = {};
  final Map<String, ItemGroup> _groups = {};
  final Map<String, Quality> _qualities = {};
  final Map<String, Map<Quality, SolidItem>> _solidItems = {};
  final Map<String, Fluid> _fluids = {};

  final Map<ItemGroup, List<ItemSubgroup>> _cachedSubGroups = {};

  Icon cacheAndRetrieveIcon({
    required Icon? icon,
    double expectedIconSize = ExpectedIconSize.other,
    Quality? quality,
  }) {
    double iconSize = icon?.size ?? expectedIconSize;

    return _iconCache.putIfAbsent(_IconCacheKey(icon, iconSize, quality), () {
      // Use default "unknown" icon when icon is absent
      Icon iconToCache =
          icon ??
          Icon([
            IconData(
              icon: '__core__/graphics/icons/unknown.png',
              iconSize: iconSize,
              expectedIconSize: expectedIconSize,
            ),
          ], iconSize);

      if (quality?.drawSpriteByDefault ?? false) {
        iconToCache = Icon([
          ...iconToCache.icons,
          ...quality!.icon.icons,
        ], iconSize);
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
  final double iconSize;
  final Quality? quality;

  @override
  final int hashCode;

  _IconCacheKey(this.icon, this.iconSize, this.quality)
    : hashCode = icon.hashCode + iconSize.hashCode + quality.hashCode;

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is _IconCacheKey &&
          icon == other.icon &&
          iconSize == other.iconSize &&
          quality == other.quality);
}
