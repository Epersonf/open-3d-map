import 'package:flutter/material.dart';
import 'transform_inspector.dart';
import 'tags_inspector.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key});

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  final List<bool> _expanded = [true, false];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      child: SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (i, isOpen) => setState(() => _expanded[i] = !isOpen),
          children: [
            ExpansionPanel(
              canTapOnHeader: true,
              headerBuilder: (ctx, isOpen) => const ListTile(title: Text('Transform', style: TextStyle(color: Colors.white))),
              body: const TransformInspector(),
              backgroundColor: Colors.transparent,
              isExpanded: _expanded[0],
            ),
            ExpansionPanel(
              canTapOnHeader: true,
              backgroundColor: Colors.transparent,
              headerBuilder: (ctx, isOpen) => const ListTile(title: Text('Tags', style: TextStyle(color: Colors.white))),
              body: const TagsInspector(),
              isExpanded: _expanded[1],
            ),
          ],
        ),
      ),
    );
  }
}
