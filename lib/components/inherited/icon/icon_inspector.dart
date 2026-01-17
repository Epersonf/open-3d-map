import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../core/utils/flutter_icons_map.dart';
import 'icon_component.dart';

class IconInspector extends StatelessWidget {
  const IconInspector({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) return const SizedBox.shrink();
      final iconComp = sel.getComponent<IconComponent>();
      if (iconComp == null) return const SizedBox.shrink();

      void update(String name) {
        final updated = sel.copyWithComponent(iconComp.copyWith(iconName: name));
        ProjectStore.instance.updateGameObject(updated);
        SelectionStore.instance.select(updated);
      }

      // Obtém o ícone atual visualmente
      final currentIconData = FlutterIconsMap.fromName(iconComp.iconName);

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Icon Select", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            
            // Linha com o ícone atual + Botão de busca
            Row(
              children: [
                // Preview do ícone atual
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(currentIconData, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                
                // Botão de Busca
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search, size: 16),
                    label: Text(iconComp.iconName, overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    onPressed: () => _showIconPicker(context, update),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showIconPicker(BuildContext context, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => _IconPickerDialog(onSelect: onSelect),
    );
  }
}

class _IconPickerDialog extends StatefulWidget {
  final Function(String) onSelect;
  const _IconPickerDialog({required this.onSelect});

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog> {
  String _search = '';
  
  @override
  Widget build(BuildContext context) {
    // Filtra as chaves do mapa baseado no texto digitado
    final allKeys = FlutterIconsMap.allNames;
    final filtered = _search.isEmpty 
        ? allKeys 
        : allKeys.where((k) => k.toLowerCase().contains(_search.toLowerCase())).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Header da busca
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search icon (e.g., "camera", "user")...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) => setState(() => _search = val),
              ),
            ),
            
            const Divider(height: 1, color: Colors.white10),

            // Grid de Ícones
            Expanded(
              child: filtered.isEmpty 
              ? const Center(child: Text("No icons found", style: TextStyle(color: Colors.white54)))
              : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 60,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final key = filtered[index];
                  final icon = FlutterIconsMap.map[key];

                  return Tooltip(
                    message: key,
                    child: InkWell(
                      onTap: () {
                        widget.onSelect(key);
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: Colors.white70, size: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
