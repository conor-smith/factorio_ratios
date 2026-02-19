import 'package:flutter/material.dart';

class SearchableDropDown extends StatefulWidget {
  final Map<String, String> nameToDisplayName;
  final void Function(String name) onPressed;

  int get length => nameToDisplayName.length;

  const SearchableDropDown({
    super.key,
    required this.nameToDisplayName,
    required this.onPressed,
  });

  @override
  State<SearchableDropDown> createState() => _SearchableDropDownState();
}

class _SearchableDropDownState extends State<SearchableDropDown> {
  final List<DropDownEntry> entryWidgets = [];

  @override
  void initState() {
    super.initState();

    widget.nameToDisplayName.forEach(
      (name, displayName) => entryWidgets.add(
        DropDownEntry(
          name: name,
          displayName: displayName,
          onPressed: () => widget.onPressed(name),
        ),
      ),
    );

    entryWidgets.sort(
      (widget1, widget2) => widget1.displayName.compareTo(widget2.displayName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: entryWidgets);
  }
}

class DropDownEntry extends StatelessWidget {
  final String name;
  final String displayName;
  final void Function() onPressed;

  const DropDownEntry({
    super.key,
    required this.name,
    required this.displayName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(displayName));
  }
}
