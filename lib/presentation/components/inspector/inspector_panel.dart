import 'package:flutter/material.dart';
import 'transform_inspector.dart';
import 'tags_inspector.dart';
import 'graphics_inspector.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key});

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  // [Graphics, Transform, Tags]
  final List<bool> _expanded = [true, true, false];

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
            // 1. Graphics Section
            _buildSectionHeader('Graphics', 0),
            if (_expanded[0])
              Container(color: const Color(0xFF121212), child: const GraphicsInspector()),

            // 2. Transform Section
            _buildSectionHeader('Transform', 1),
            if (_expanded[1])
              Container(color: const Color(0xFF121212), child: const TransformInspector()),
            
            // 3. Tags Section
            _buildSectionHeader('Tags', 2),
            if (_expanded[2])
              Container(color: const Color(0xFF121212), child: const TagsInspector()),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int index) {
    return Container(
      decoration: BoxDecoration(
        color: _expanded[index] ? const Color(0xFF1A1A1A) : const Color(0xFF0F0F0F),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.3))),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Icon(
          _expanded[index] ? Icons.expand_less : Icons.expand_more,
          color: Colors.white70,
        ),
        onTap: () {
          setState(() {
            _expanded[index] = !_expanded[index];
          });
        },
      ),
    );
  }
}
