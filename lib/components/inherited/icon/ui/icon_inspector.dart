import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../../core/utils/flutter_icons_map.dart';
import '../icon_component.dart';
import 'icon_picker_dialog.dart';

class IconInspector extends StatelessWidget {
  const IconInspector({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) return const SizedBox.shrink();
      final iconComp = sel.getComponent<IconComponent>();
      if (iconComp == null) return const SizedBox.shrink();

      void update({String? name, double? size}) {
        final updated = sel.copyWithComponent(iconComp.copyWith(
          iconName: name,
          iconSize: size,
        ));
        ProjectStore.instance.updateGameObject(updated);
        SelectionStore.instance.select(updated);
      }

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
            // <-- Faltava essa linha no seu código original
            Text("Icon Settings", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),

            // --- SELETOR DE ÍCONE ---
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(currentIconData, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search, size: 16),
                    label: Text(iconComp.iconName,
                        overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                    onPressed: () =>
                        _showIconPicker(context, (n) => update(name: n)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),

            // --- SLIDER DE TAMANHO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Size", style: TextStyle(color: Colors.white70)),
                Text(iconComp.iconSize.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.blueAccent,
                inactiveTrackColor: Colors.black26,
                thumbColor: Colors.white,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: iconComp.iconSize,
                min: 0.1,
                max: 5.0,
                onChanged: (val) => update(size: val),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showIconPicker(BuildContext context, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => IconPickerDialog(onSelect: onSelect),
    );
  }
}
