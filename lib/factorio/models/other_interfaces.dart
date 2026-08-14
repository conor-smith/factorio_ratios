part of 'models.dart';

abstract class Prototype implements Comparable<Prototype> {
  String get name;
  String get type;
  String get localisedName;
  String get order;
  ItemSubgroup? get subgroup;

  @override
  int compareTo(Prototype other) => compareTwoPrototypes(this, other);

  @override
  String toString() => name;
}

// Not technically a factorio type, but helpful for this use case
abstract class PrototypeWithIcon extends Prototype {
  Icon? get icon;
}

int compareTwoPrototypes(Prototype prototype1, Prototype prototype2) {
  var order = prototype1.order.compareTo(prototype2.order);

  return order != 0 ? order : prototype1.name.compareTo(prototype2.name);
}
