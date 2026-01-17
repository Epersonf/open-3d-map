import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:path/path.dart' as p;
import '../../../../../stores/selection_store.dart';
import '../../../../../stores/project_store.dart';
import '../mesh_component.dart';
import 'asset_picker_dialog.dart'; // Importe o arquivo criado acima

class MeshInspector extends StatelessWidget {
  const MeshInspector({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) return const SizedBox.shrink();

      final mesh = sel.getComponent<MeshComponent>();
      if (mesh == null) return const Text('No Mesh Component');

      // Helper para buscar o asset no ProjectStore pelo ID
      String assetName = 'None';
      if (mesh.assetId != null) {
        final project = ProjectStore.instance.project;
        if (project != null) {
          try {
            final asset = project.assets.firstWhere((a) => a.id == mesh.assetId);
            assetName = p.basename(asset.path);
          } catch (_) {
            assetName = 'Unknown ID';
          }
        }
      }

      void updateMesh(String newAssetId) {
        final updated = sel.copyWithComponent(mesh.copyWith(assetId: newAssetId));
        ProjectStore.instance.updateGameObject(updated);
        SelectionStore.instance.select(updated);
      }

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mesh Model', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),

            // --- SELETOR DE MESH (Estilo Botão/Explorer) ---
            Row(
              children: [
                // Ícone visual
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.view_in_ar, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                
                // Botão com nome e ação
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: Text(
                      assetName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () async {
                      final newId = await showDialog<String>(
                        context: context,
                        builder: (ctx) => const AssetPickerDialog(),
                      );
                      
                      if (newId != null) {
                        updateMesh(newId);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10),

            // --- CONTROLES EXTRAS ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blueAccent,
              title: const Text('Visible in Runtime',
                  style: TextStyle(color: Colors.white70)),
              value: mesh.visibleInRuntime,
              onChanged: (val) {
                final updated =
                    sel.copyWithComponent(mesh.copyWith(visibleInRuntime: val));
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
