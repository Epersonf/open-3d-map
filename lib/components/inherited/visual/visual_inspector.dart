import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:open_3d_mapper/components/inherited/visual/visual_component.dart';
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';

class VisualInspector extends StatelessWidget {
  const VisualInspector({super.key});

  void _updateVisual(VisualComponent newVisual) {
    final sel = SelectionStore.instance.selected;
    if (sel == null) return;
    final updated = sel.copyWithComponent(newVisual);
    ProjectStore.instance.updateGameObject(updated);
    SelectionStore.instance.select(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) return const SizedBox.shrink();
      final visual = sel.getComponent<VisualComponent>();
      if (visual == null) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: const Text(
            'No Visual Component found',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF121212),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selector
            Row(
              children: [
                const Text('Type:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                DropdownButton<VisualType>(
                  value: visual.type,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white),
                  underline: Container(height: 1, color: Colors.blue),
                  items: VisualType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _updateVisual(visual.copyWith(type: val));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // MESH SETTINGS
            if (visual.type == VisualType.mesh) ...[
              const Text('Mesh Asset ID:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  visual.assetId ?? 'None',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
               const SizedBox(height: 4),
               const Text('Drag a file from explorer to update', style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],

            // ICON SETTINGS
            if (visual.type == VisualType.icon) ...[
              const Text('Select Icon:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _IconOption(name: 'light', current: visual.iconName, onTap: (n) => _updateVisual(visual.copyWith(iconName: n))),
                  _IconOption(name: 'camera', current: visual.iconName, onTap: (n) => _updateVisual(visual.copyWith(iconName: n))),
                  _IconOption(name: 'spawn', current: visual.iconName, onTap: (n) => _updateVisual(visual.copyWith(iconName: n))),
                  _IconOption(name: 'enemy', current: visual.iconName, onTap: (n) => _updateVisual(visual.copyWith(iconName: n))),
                ],
              ),
            ],

            const SizedBox(height: 16),
            // RUNTIME VISIBILITY TOGGLE
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible in Runtime', style: TextStyle(color: Colors.white70, fontSize: 14)),
              value: visual.visibleInRuntime,
              activeColor: Colors.blue,
              onChanged: (val) => _updateVisual(visual.copyWith(visibleInRuntime: val)),
            ),
          ],
        ),
      );
    });
  }
}

class _IconOption extends StatelessWidget {
  final String name;
  final String? current;
  final Function(String) onTap;

  const _IconOption({required this.name, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == name;
    return InkWell(
      onTap: () => onTap(name),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : const Color(0xFF222222),
          border: Border.all(color: isSelected ? Colors.blue : Colors.white12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(_getIconData(name), color: Colors.white, size: 20),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch(name) {
      case 'light': return Icons.lightbulb;
      case 'camera': return Icons.videocam;
      case 'spawn': return Icons.flag;
      case 'enemy': return Icons.bug_report;
      default: return Icons.image;
    }
  }
}
