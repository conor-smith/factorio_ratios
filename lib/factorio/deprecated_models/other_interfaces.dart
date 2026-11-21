part of 'models.dart';

abstract class Prototype implements Comparable<Prototype> {
  FactorioDatabase get factorioDb;

  String get name;
  String get type;
  String get localisedName;
  String get order;
  ItemSubgroup? get subgroup;

  @override
  int compareTo(Prototype other) {
    var toReturn = order.compareTo(other.order);

    return toReturn != 0 ? toReturn : name.compareTo(other.name);
  }

  @override
  String toString() => name;
}

// Not technically a factorio type, but helpful for this use case
abstract class PrototypeWithIcon extends Prototype {
  Icon? get icon;
}
