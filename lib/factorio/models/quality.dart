part of 'models.dart';

class Quality
    with PrototypeDelegator, BasicPrototype
    implements PrototypeWithIcon {
  @override
  final FactorioDatabase _database;
  @override
  final QualityJson _internalPrototype;

  @override
  late final ItemSubgroup? subgroup = _getSubgroup();
  @override
  late final Icon icon = _database.cacheAndRetrieveIcon(
    icon: _internalPrototype.icon,
    expectedIconSize: expectedIconSize,
  );

  late final Quality? next = _database._qualities[_internalPrototype.next];
  late final Quality? previous = _database._qualities.values
      .where((quality) => quality.next == this)
      .firstOrNull;

  bool get drawSpriteByDefault => _internalPrototype.drawSpriteByDefault;
  @override
  double get expectedIconSize => ExpectedIconSize.other;

  Quality({required this._database, required this._internalPrototype});

  QualityCompare compareToQuality(Quality other) {
    if (this == other) {
      return QualityCompare.equalTo;
    } else {
      var nextInChain = next;

      while (nextInChain != null) {
        if (nextInChain == other) {
          return QualityCompare.lessThan;
        } else {
          nextInChain = nextInChain.next;
        }
      }

      nextInChain = other.next;
      while (nextInChain != null) {
        if (nextInChain == this) {
          return QualityCompare.greaterThan;
        } else {
          nextInChain = nextInChain.next;
        }
      }

      return QualityCompare.notInChain;
    }
  }
}

enum QualityCompare { equalTo, greaterThan, lessThan, notInChain }
