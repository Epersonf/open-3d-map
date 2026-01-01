import 'package:flutter/material.dart' hide Transform;
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../stores/selection_store.dart';
import '../../../stores/project_store.dart';
import '../../../domain/scene/transform.dart';
import '../../../domain/scene/game_object.dart';

class TransformInspector extends StatefulWidget {
  const TransformInspector({super.key});

  @override
  State<TransformInspector> createState() => _TransformInspectorState();
}

class _TransformInspectorState extends State<TransformInspector> {
  final TextEditingController px = TextEditingController(text: '0');
  final TextEditingController py = TextEditingController(text: '0');
  final TextEditingController pz = TextEditingController(text: '0');

  final TextEditingController rx = TextEditingController(text: '0');
  final TextEditingController ry = TextEditingController(text: '0');
  final TextEditingController rz = TextEditingController(text: '0');

  final TextEditingController sx = TextEditingController(text: '1');
  final TextEditingController sy = TextEditingController(text: '1');
  final TextEditingController sz = TextEditingController(text: '1');

  @override
  void dispose() {
    px.dispose();
    py.dispose();
    pz.dispose();
    rx.dispose();
    ry.dispose();
    rz.dispose();
    sx.dispose();
    sy.dispose();
    sz.dispose();
    super.dispose();
  }

  Widget _tripleField(String label, TextEditingController a, TextEditingController b, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: TextField(controller: a, decoration: const InputDecoration(labelText: 'X'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: b, decoration: const InputDecoration(labelText: 'Y'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: c, decoration: const InputDecoration(labelText: 'Z'))),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) {
        return Container(padding: const EdgeInsets.all(12), child: const Text('No selection', style: TextStyle(color: Colors.white70)));
      }

      // update controllers only when selection changes
      // (avoid clobbering while user types)
      if (_currentSelectedId != sel.id) {
        _currentSelectedId = sel.id;
        px.text = sel.transform.position.x.toString();
        py.text = sel.transform.position.y.toString();
        pz.text = sel.transform.position.z.toString();

        rx.text = sel.transform.rotation.x.toString();
        ry.text = sel.transform.rotation.y.toString();
        rz.text = sel.transform.rotation.z.toString();

        sx.text = sel.transform.scale.x.toString();
        sy.text = sel.transform.scale.y.toString();
        sz.text = sel.transform.scale.z.toString();
      }

      return Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _tripleField('Position', px, py, pz),
            _tripleField('Rotation', rx, ry, rz),
            _tripleField('Scale', sx, sy, sz),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // apply transform
                    final newTransform = Transform(
                      position: Vec3(x: double.tryParse(px.text) ?? 0.0, y: double.tryParse(py.text) ?? 0.0, z: double.tryParse(pz.text) ?? 0.0),
                      rotation: Vec3(x: double.tryParse(rx.text) ?? 0.0, y: double.tryParse(ry.text) ?? 0.0, z: double.tryParse(rz.text) ?? 0.0),
                      scale: Vec3(x: double.tryParse(sx.text) ?? 1.0, y: double.tryParse(sy.text) ?? 1.0, z: double.tryParse(sz.text) ?? 1.0),
                    );
                    final updated = GameObject(
                      id: sel.id,
                      name: sel.name,
                      parentId: sel.parentId,
                      assetId: sel.assetId,
                      transform: newTransform,
                      tags: Map.from(sel.tags),
                      children: sel.children,
                    );
                    ProjectStore.instance.updateGameObject(updated);
                    SelectionStore.instance.select(updated);
                  },
                  child: const Text('Apply Transform'),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: () => SelectionStore.instance.clear(), child: const Text('Deselect')),
              ],
            ),
          ],
        ),
      );
    });
  }

  String? _currentSelectedId;
}
