part of 'models.dart';

class Quality with BasicPrototype implements PrototypeWithIcon {
  @override
  final FactorioDatabase _database;
  @override
  final QualityJson _internalPrototype;

  @override
  late final String localName = _getLocalName(
    _database,
    name,
    _internalPrototype.localisedName,
  );
  @override
  late final ItemSubgroup? subgroup = _getSubgroup(
    _database,
    _internalPrototype,
  );
  @override
  late final Icon icon = throw UnimplementedError();

  late final Quality? next = _database._qualities[_internalPrototype.next];
  late final Quality? previous = _database._qualities.values
      .where((quality) => quality.next == this)
      .firstOrNull;

  bool get drawSpriteByDefault => _internalPrototype.drawSpriteByDefault;

  @override
  String get name => _internalPrototype.name;
  @override
  String get type => _internalPrototype.type;
  @override
  String get order => _internalPrototype.order;

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
