part of 'data_dump.dart';

class DDItemGroup extends DDPrototypeWithIcon {
  DDItemGroup.fromJson(Map json)
    : super.fromJson(json, ExpectedIconSize.itemGroup);
}
