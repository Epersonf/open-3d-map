import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
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

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _btn('spawn', Icons.flag, iconComp.iconName, update),
            _btn('light', Icons.lightbulb, iconComp.iconName, update),
            _btn('camera', Icons.videocam, iconComp.iconName, update),
            _btn('enemy', Icons.bug_report, iconComp.iconName, update),
          ],
        ),
      );
    });
  }

  Widget _btn(String name, IconData icon, String current, Function(String) onTap) {
    final selected = name == current;
    return InkWell(
      onTap: () => onTap(name),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.3) : Colors.white10,
          border: Border.all(color: selected ? Colors.blue : Colors.transparent),
          borderRadius: BorderRadius.circular(4)
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
