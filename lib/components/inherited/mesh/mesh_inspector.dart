import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import 'mesh_component.dart';

class MeshInspector extends StatelessWidget {
  const MeshInspector({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) return const SizedBox.shrink();
      
      final mesh = sel.getComponent<MeshComponent>();
      if (mesh == null) return const Text('No Mesh Component');

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asset ID:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(mesh.assetId ?? 'None', style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible in Runtime', style: TextStyle(color: Colors.white70)),
              value: mesh.visibleInRuntime,
              onChanged: (val) {
                final updated = sel.copyWithComponent(mesh.copyWith(visibleInRuntime: val));
                ProjectStore.instance.updateGameObject(updated);
                SelectionStore.instance.select(updated);
              },
            ),
          ],
        ),
      );
    });
  }
}
