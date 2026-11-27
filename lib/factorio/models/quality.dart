part of 'models.dart';

class Quality extends PrototypeWithIcon {
  @override
  final QualityJson _internalJson;

  late final Quality? next = _getNext();
  late final Quality? previous = _getPrevious();

  Quality({required super.database, required this._internalJson});

  Quality? _getNext() => _database._qualities[_internalJson.next];
  Quality? _getPrevious() => _database._qualities.values
      .where((quality) => quality.next == this)
      .firstOrNull;

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
