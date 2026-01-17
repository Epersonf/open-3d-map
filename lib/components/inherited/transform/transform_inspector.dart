import 'dart:async';

import 'package:flutter/material.dart' hide Transform;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import '../../../stores/selection_store.dart';
import '../../../stores/project_store.dart';

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
    if (sel == null)
      return; // Removida verificação de _currentObject para evitar stale state

    final newTransform = TransformComponent(
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
    final updated = sel.copyWithComponent(newTransform);
    ProjectStore.instance.updateGameObject(updated);
    SelectionStore.instance.select(updated);
  }

  void _scheduleApply() {
    _applyTimer?.cancel();
    _applyTimer = Timer(const Duration(milliseconds: 500), _applyTransform);
  }

  /// Método auxiliar seguro para atualizar o texto do controlador
  /// Ele verifica se o valor realmente mudou para evitar loop ou reset de cursor enquanto digita
  void _updateControllerIfNeeded(TextEditingController ctrl, double value) {
    // 1. Pega o valor atual que está no texto
    double? currentTextVal = double.tryParse(ctrl.text);

    // 2. Se for nulo ou a diferença for significativa, atualiza
    // Usamos um pequeno epsilon para evitar 'flickering' de floating point
    if (currentTextVal == null || (currentTextVal - value).abs() > 0.001) {
      // Verificação extra: Se o widget tem foco, o usuário pode estar digitando "10."
      // Se atualizarmos para "10.00" agora, atrapalha a digitação.
      // Mas como o Gizmo é arrastado no Viewport, o TextField NÃO tem foco.
      ctrl.text = value.toStringAsFixed(2);
    }
  }

  Widget _tripleField(String label, TextEditingController a,
      TextEditingController b, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInput(a, 'X')),
              const SizedBox(width: 8),
              Expanded(child: _buildInput(b, 'Y')),
              const SizedBox(width: 8),
              Expanded(child: _buildInput(c, 'Z')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
      ),
      onChanged: (_) => _scheduleApply(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: const Text(
            'No object selected',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      var transformComp = sel.getComponent<TransformComponent>();
      if (transformComp == null) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: const Text(
            'No Transform Component found',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      _updateControllerIfNeeded(px, transformComp.position.x);
      _updateControllerIfNeeded(py, transformComp.position.y);
      _updateControllerIfNeeded(pz, transformComp.position.z);

      _updateControllerIfNeeded(rx, transformComp.rotation.x);
      _updateControllerIfNeeded(ry, transformComp.rotation.y);
      _updateControllerIfNeeded(rz, transformComp.rotation.z);
      _updateControllerIfNeeded(sx, transformComp.scale.x);
      _updateControllerIfNeeded(sy, transformComp.scale.y);
      _updateControllerIfNeeded(sz, transformComp.scale.z);

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
