part of 'models.dart';

class Quality extends PrototypeWithIcon {
  @override
  final DDQuality _internalPrototype;

  bool get drawSpriteByDefault => _internalPrototype.drawSpriteByDefault;

  Quality? get next => null; // TODO

  Quality({required this._internalPrototype, required super.database})
    : super(icon: _internalPrototype.icon);

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
