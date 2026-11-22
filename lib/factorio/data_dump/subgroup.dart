part of 'data_dump.dart';

class DDItemSubgroup extends DDPrototype {
  final String group;

  DDItemSubgroup.fromJson(super.json) : group = json['group'], super.fromJson();
}
