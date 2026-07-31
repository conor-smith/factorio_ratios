import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:factorio_ratios/ui/factorio_icon_menu.dart';
import 'package:factorio_ratios/ui/icon_widgets.dart';
import 'package:factorio_ratios/utility/flutter.dart' as utility;
import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/material.dart' hide Icon;
import 'package:flutter/services.dart';

const List<LogicalKeyboardKey> _shiftKeys = [
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.shift,
];

class GraphWidget extends StatefulWidget {
  final Graph graph;

  const GraphWidget({super.key, required this.graph});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  FocusNode focusNode = FocusNode();
  _GraphWidgetOperation operation = _GraphWidgetOperation.noOperation;

  PointerDownEvent? gestureStart;
  bool shiftKeyHeld = false;

  Widget overlayMenu = const Placeholder();

  Graph get graph => widget.graph;

  @override
  void initState() {
    super.initState();

    focusNode.requestFocus();
  }

  @override
  void dispose() {
    super.dispose();

    focusNode.dispose();
  }

  void handleKeyEvent(KeyEvent event) {
    if (_shiftKeys.contains(event.logicalKey)) {
      if (event is KeyDownEvent) {
        shiftKeyHeld = true;
      } else if (event is KeyUpEvent) {
        shiftKeyHeld = false;
      }

      if (operation == _GraphWidgetOperation.noOperation) {
        setState(() {});
      }
    }
  }

  void beginGesture(PointerDownEvent event) {
    gestureStart = event;

    if (shiftKeyHeld && event.buttons == gestures.kPrimaryButton) {
      setState(() {
        operation = _GraphWidgetOperation.shiftGesture;
      });
    } else {
      operation = _GraphWidgetOperation.nonShiftGesture;
    }
  }

  void cancelGesture(_) {
    setState(() {
      operation = _GraphWidgetOperation.noOperation;
      gestureStart = null;
    });
  }

  void endGesture(PointerUpEvent event) {
    if (gestureStart == null) {
      setState(() {
        operation = _GraphWidgetOperation.noOperation;
      });
      return;
    }

    if (utility.isSimpleClick(gestureStart!, event) &&
        gestureStart!.buttons == gestures.kSecondaryButton) {
      createContextMenu(event.position, event.localPosition);
    } else {
      setState(() {
        operation = _GraphWidgetOperation.noOperation;
      });
    }

    gestureStart = null;
  }

  void beginElementOperation() {
    setState(() {
      operation = _GraphWidgetOperation.elementOperation;
    });
  }

  void endElementOperation() {
    setState(() {
      operation = _GraphWidgetOperation.noOperation;
    });
  }

  void createContextMenu(Offset screenPosition, Offset graphPosition) {
    setState(() {
      operation = _GraphWidgetOperation.overlayMenu;

      overlayMenu = ContextMenu(
        screenLocation: screenPosition,
        options: [
          MenuOption(
            text: 'Create consumer node',
            operation: () => createConsumerMenu(graphPosition),
          ),
          MenuOption(
            text: 'Build full graph',
            operation: () => graph.fulfillAllNodeIo(),
          ),
        ],
      );
    });
  }

  void createConsumerMenu(Offset graphPosition) {
    setState(() {
      operation = _GraphWidgetOperation.overlayMenu;

      overlayMenu = Center(
        child: FactorioIconMenuWidget<Item>(
          itemGroups: graph.basePlanner.validConsumerNodeItems,
          onSelected: (item) {
            graph.addNode(
              nodeType: NodeType.consumer,
              productionLine: MagicLine.singleItemConsumer(InGameItem(item)),
              initialPosition: graphPosition,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      GraphWindow(
        key: BasePlannerElementKey(graph),
        nodes: graph.allNodes,
        edges: graph.edges,
        transformEnabled: operation.transformEnabled && !shiftKeyHeld,
        shiftKeyHeld: shiftKeyHeld,
        onPointerDown: beginGesture,
        onPointerCancel: cancelGesture,
        onPointerUp: endGesture,
        beginElementOperation: beginElementOperation,
        endElementOperation: endElementOperation,
      ),
      GraphOverlay(icon: graph.icon, name: graph.name),
    ];

    if (operation == _GraphWidgetOperation.overlayMenu) {
      children
        ..add(
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerUp: (_) => setState(() {
              operation = _GraphWidgetOperation.noOperation;
            }),
          ),
        )
        ..add(overlayMenu);
    }

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: handleKeyEvent,
      child: Stack(fit: StackFit.expand, children: children),
    );
  }
}

class GraphOverlay extends StatelessWidget {
  final Icon? icon;
  final String name;

  const GraphOverlay({super.key, required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black)),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.all(5),
                child: IconWidgetCache.get(icon),
              ),
              Text(name),
            ],
          ),
        ),
      ],
    );
  }
}

class GraphWindow extends StatelessWidget {
  final Iterable<NodeElement> nodes;
  final Iterable<Edge> edges;

  final bool transformEnabled;
  final bool shiftKeyHeld;
  final Function(PointerDownEvent) onPointerDown;
  final Function(PointerCancelEvent) onPointerCancel;
  final Function(PointerUpEvent) onPointerUp;
  final Function() beginElementOperation;
  final Function() endElementOperation;

  const GraphWindow({
    super.key,
    required this.nodes,
    required this.edges,
    required this.transformEnabled,
    required this.shiftKeyHeld,
    required this.onPointerDown,
    required this.onPointerCancel,
    required this.onPointerUp,
    required this.beginElementOperation,
    required this.endElementOperation,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panEnabled: transformEnabled,
      scaleEnabled: transformEnabled,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: onPointerDown,
            onPointerCancel: onPointerCancel,
            onPointerUp: onPointerUp,
          ),
          ...nodes.map(
            (node) => NodeWidget(
              key: BasePlannerElementKey(node),
              node: node,
              shiftKeyHeld: shiftKeyHeld,
              beginElementOperation: beginElementOperation,
              endElementOperation: endElementOperation,
            ),
          ),
          ...edges.map(
            (edge) => EdgeWidget(key: BasePlannerElementKey(edge), edge: edge),
          ),
        ],
      ),
    );
  }
}

class ContextMenu extends StatelessWidget {
  final Offset screenLocation;
  final List<MenuOption> options;

  const ContextMenu({
    super.key,
    required this.screenLocation,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: screenLocation.dy,
      left: screenLocation.dx,
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
  final Function() operation;

  const MenuOption({super.key, required this.text, required this.operation});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: operation, child: Text(text));
  }
}

class BasePlannerElementKey extends LocalKey {
  final BasePlannerElement element;

  const BasePlannerElementKey(this.element);

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is BasePlannerElementKey && other.element == element);

  @override
  int get hashCode => element.hashCode;
}

enum _GraphWidgetOperation {
  noOperation(true),
  shiftGesture(false),
  nonShiftGesture(true),
  overlayMenu(false),
  elementOperation(false);

  final bool transformEnabled;

  const _GraphWidgetOperation(this.transformEnabled);
}
