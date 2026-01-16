import 'package:flutter/material.dart';
import 'package:open_3d_mapper/stores/selection_store.dart';
import '../../../components/core/component_registry.dart' as comp_ui;

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key});

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
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
}
