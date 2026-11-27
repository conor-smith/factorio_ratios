part of 'models.dart';

class Quality extends PrototypeWithIcon {
  @override
  final QualityJson _internalPrototype;

  bool get drawSpriteByDefault => _internalPrototype.drawSpriteByDefault;

  @relationship
  late final Quality? next = _database._qualities[_internalPrototype.next];
  @relationship
  late final Quality? previous = _database._qualities.values
      .where((quality) => quality.next == this)
      .firstOrNull;

  Quality({required super.database, required this._internalPrototype});

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
