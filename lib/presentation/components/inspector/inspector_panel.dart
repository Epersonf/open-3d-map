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
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Transform section
            Container(
              decoration: BoxDecoration(
                color: _expanded[0] ? Color(0xFF1A1A1A) : Color(0xFF0F0F0F),
                border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.3)),
                ),
              ),
              child: ListTile(
                title: const Text('Transform', style: TextStyle(color: Colors.white)),
                trailing: Icon(
                  _expanded[0] ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
                onTap: () {
                  setState(() {
                    _expanded[0] = !_expanded[0];
                  });
                },
              ),
            ),
            if (_expanded[0])
              Container(
                color: const Color(0xFF121212),
                child: const TransformInspector(),
              ),
            
            // Tags section
            Container(
              decoration: BoxDecoration(
                color: _expanded[1] ? Color(0xFF1A1A1A) : Color(0xFF0F0F0F),
                border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.3)),
                ),
              ),
              child: ListTile(
                title: const Text('Tags', style: TextStyle(color: Colors.white)),
                trailing: Icon(
                  _expanded[1] ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
                onTap: () {
                  setState(() {
                    _expanded[1] = !_expanded[1];
                  });
                },
              ),
            ),
            if (_expanded[1])
              Container(
                color: const Color(0xFF121212),
                child: const TagsInspector(),
              ),
          ],
        ),
      ),
    );
  }
}
