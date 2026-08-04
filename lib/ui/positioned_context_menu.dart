import 'package:flutter/material.dart';

class PositionedContextMenu extends StatelessWidget {
  final Offset position;
  final List<MenuOption> options;

  const PositionedContextMenu({
    super.key,
    required this.position,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options,
        ),
      ),
    );
  }
}

class MenuOption extends StatelessWidget {
  final String text;
  final Function() action;

  const MenuOption({super.key, required this.text, required this.action});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: action, child: Text(text));
  }
}
