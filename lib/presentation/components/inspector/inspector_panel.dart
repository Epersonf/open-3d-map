import 'package:flutter/material.dart';
import 'package:open_3d_mapper/stores/selection_store.dart';
import '../../../components/core/component_registry.dart' as comp_ui;

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
            // Dynamic component inspectors
            Builder(builder: (_) {
              final sel = SelectionStore.instance.selected;
              if (sel == null) return const SizedBox.shrink();

              return Column(
                children: sel.components.map((component) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: const Color(0xFF1A1A1A),
                        width: double.infinity,
                        child: Text(
                          component.id.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(color: const Color(0xFF121212), child: comp_ui.ComponentRegistry.createInspector(component)),
                    ],
                  );
                }).toList(),
              );
            }),
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
