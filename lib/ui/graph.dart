import 'package:flutter/material.dart';

class GraphWidget extends LeafRenderObjectWidget {
  const GraphWidget({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphBox();
  }
}

class GraphBox extends RenderBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()..color = Colors.red;
    context.canvas.drawRect(offset & size, paint);
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }
}
