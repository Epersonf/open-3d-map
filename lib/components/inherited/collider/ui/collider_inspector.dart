import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../../domain/general/vec3.dart';
import '../collider_component.dart';
import '../collider_enums.dart';

class ColliderInspector extends StatefulWidget {
  const ColliderInspector({super.key});

  @override
  State<ColliderInspector> createState() => _ColliderInspectorState();
}

class _ColliderInspectorState extends State<ColliderInspector> {
  // Controllers
  final cx = TextEditingController();
  final cy = TextEditingController();
  final cz = TextEditingController();
  
  final sx = TextEditingController();
  final sy = TextEditingController();
  final sz = TextEditingController();
  
  final rad = TextEditingController();

  // Helper para atualizar controllers sem loop de digitação
  void _updateCtrl(TextEditingController ctrl, double val) {
    if (double.tryParse(ctrl.text) != val) {
      ctrl.text = val.toString();
    }
  }

  @override
  void dispose() {
    cx.dispose(); cy.dispose(); cz.dispose();
    sx.dispose(); sy.dispose(); sz.dispose();
    rad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) return const SizedBox.shrink();

      final collider = sel.getComponent<ColliderComponent>();
      if (collider == null) return const Text('No Collider Component');

      // Sync UI values from Component
      _updateCtrl(cx, collider.center.x);
      _updateCtrl(cy, collider.center.y);
      _updateCtrl(cz, collider.center.z);
      
      if (collider.type == ColliderType.box) {
        _updateCtrl(sx, collider.size.x);
        _updateCtrl(sy, collider.size.y);
        _updateCtrl(sz, collider.size.z);
      } else if (collider.type == ColliderType.sphere) {
        _updateCtrl(rad, collider.radius);
      }

      void update({
        ColliderType? type,
        Vec3? center,
        Vec3? size,
        double? radius,
        bool? isTrigger,
        bool? convex,
      }) {
        final updated = sel.copyWithComponent(collider.copyWith(
          type: type,
          center: center,
          size: size,
          radius: radius,
          isTrigger: isTrigger,
          convex: convex,
        ));
        ProjectStore.instance.updateGameObject(updated);
        SelectionStore.instance.select(updated);
      }

      void onCenterChanged() {
        final val = Vec3(
          x: double.tryParse(cx.text) ?? 0,
          y: double.tryParse(cy.text) ?? 0,
          z: double.tryParse(cz.text) ?? 0,
        );
        update(center: val);
      }

      void onSizeChanged() {
        final val = Vec3(
          x: double.tryParse(sx.text) ?? 1,
          y: double.tryParse(sy.text) ?? 1,
          z: double.tryParse(sz.text) ?? 1,
        );
        update(size: val);
      }

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Is Trigger & Type ---
            Row(
              children: [
                const Text("Is Trigger", style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Switch(
                  value: collider.isTrigger,
                  activeColor: Colors.greenAccent,
                  onChanged: (v) => update(isTrigger: v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Type Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ColliderType>(
                  value: collider.type,
                  dropdownColor: const Color(0xFF2A2A2A),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: ColliderType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) update(type: val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Common: Center ---
            _buildVector3Field("Center", cx, cy, cz, onCenterChanged),
            
            // --- Type Specific Fields ---
            if (collider.type == ColliderType.box) ...[
              const SizedBox(height: 12),
              _buildVector3Field("Size", sx, sy, sz, onSizeChanged),
            ],

            if (collider.type == ColliderType.sphere) ...[
              const SizedBox(height: 12),
              _buildSingleField("Radius", rad, (val) {
                update(radius: double.tryParse(val) ?? 0.5);
              }),
            ],

            if (collider.type == ColliderType.mesh) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Convex", style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Switch(
                    value: collider.convex,
                    activeColor: Colors.blueAccent,
                    onChanged: (v) => update(convex: v),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Uses the rendered mesh for collision.",
                  style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              )
            ],
          ],
        ),
      );
    });
  }

  Widget _buildVector3Field(String label, TextEditingController c1, TextEditingController c2, TextEditingController c3, VoidCallback onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _buildInput(c1, "X", onChanged)),
            const SizedBox(width: 8),
            Expanded(child: _buildInput(c2, "Y", onChanged)),
            const SizedBox(width: 8),
            Expanded(child: _buildInput(c3, "Z", onChanged)),
          ],
        )
      ],
    );
  }

  Widget _buildSingleField(String label, TextEditingController ctrl, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
         const SizedBox(height: 4),
         _buildInput(ctrl, "", () => onChanged(ctrl.text)),
      ],
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, VoidCallback onChanged) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(4)),
        labelStyle: const TextStyle(color: Colors.white38),
      ),
    );
  }
}
