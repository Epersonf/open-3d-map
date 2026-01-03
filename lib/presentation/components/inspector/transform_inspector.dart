import 'dart:async';

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

  String? _currentSelectedId;
  GameObject? _currentObject;
  Timer? _applyTimer;

  @override
  void dispose() {
    _applyTimer?.cancel();
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

  void _applyTransform() {
    final sel = SelectionStore.instance.selected;
    if (sel == null || _currentObject == null) return;

    final newTransform = Transform(
      position: Vec3(
        x: double.tryParse(px.text) ?? 0.0,
        y: double.tryParse(py.text) ?? 0.0,
        z: double.tryParse(pz.text) ?? 0.0,
      ),
      rotation: Vec3(
        x: double.tryParse(rx.text) ?? 0.0,
        y: double.tryParse(ry.text) ?? 0.0,
        z: double.tryParse(rz.text) ?? 0.0,
      ),
      scale: Vec3(
        x: double.tryParse(sx.text) ?? 1.0,
        y: double.tryParse(sy.text) ?? 1.0,
        z: double.tryParse(sz.text) ?? 1.0,
      ),
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
  }

  void _scheduleApply() {
    _applyTimer?.cancel();
    _applyTimer = Timer(const Duration(milliseconds: 500), _applyTransform);
  }

  Widget _tripleField(String label, TextEditingController a, TextEditingController b, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: a,
                  decoration: const InputDecoration(
                    labelText: 'X',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _scheduleApply(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: b,
                  decoration: const InputDecoration(
                    labelText: 'Y',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _scheduleApply(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    labelText: 'Z',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _scheduleApply(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) {
        _currentSelectedId = null;
        _currentObject = null;
        return Container(
          padding: const EdgeInsets.all(12),
          child: const Text(
            'No object selected',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      // update controllers only when selection changes
      if (_currentSelectedId != sel.id) {
        _applyTimer?.cancel();
        _currentSelectedId = sel.id;
        _currentObject = sel;
        
        px.text = sel.transform.position.x.toStringAsFixed(2);
        py.text = sel.transform.position.y.toStringAsFixed(2);
        pz.text = sel.transform.position.z.toStringAsFixed(2);

        rx.text = sel.transform.rotation.x.toStringAsFixed(2);
        ry.text = sel.transform.rotation.y.toStringAsFixed(2);
        rz.text = sel.transform.rotation.z.toStringAsFixed(2);

        sx.text = sel.transform.scale.x.toStringAsFixed(2);
        sy.text = sel.transform.scale.y.toStringAsFixed(2);
        sz.text = sel.transform.scale.z.toStringAsFixed(2);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tripleField('Position', px, py, pz),
          _tripleField('Rotation', rx, ry, rz),
          _tripleField('Scale', sx, sy, sz),
        ],
      );
    });
  }
}