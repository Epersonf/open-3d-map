import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';

import '../../../../domain/scene/game_object.dart';
import '../../../../stores/tool_store.dart';

class GizmoTransformLogic {
  /// Calcula e retorna um NOVO GameObject com as transformações aplicadas
  static GameObject applyTransform({
    required GameObject original,
    required GizmoMode mode,
    required String axis,
    required double delta,
  }) {
    var transformComp = original.getComponent<TransformComponent>();
    if (transformComp == null) {
      return original;
    }
    double px = transformComp.position.x;
    double py = transformComp.position.y;
    double pz = transformComp.position.z;
    double rx = transformComp.rotation.x;
    double ry = transformComp.rotation.y;
    double rz = transformComp.rotation.z;
    double sx = transformComp.scale.x;
    double sy = transformComp.scale.y;
    double sz = transformComp.scale.z;

    if (mode == GizmoMode.translate) {
      if (axis == 'X') px += delta;
      if (axis == 'Y') py += delta;
      if (axis == 'Z') pz += delta;
    } else if (mode == GizmoMode.scale) {
      if (axis == 'X') sx += delta;
      if (axis == 'Y') sy += delta;
      if (axis == 'Z') sz += delta;
      if (sx < 0.01) sx = 0.01;
      if (sy < 0.01) sy = 0.01;
      if (sz < 0.01) sz = 0.01;
    } else if (mode == GizmoMode.rotate) {
      if (axis == 'X') rx += delta;
      if (axis == 'Y') ry += delta;
      if (axis == 'Z') rz += delta;
    }

    return GameObject(
      id: original.id,
      name: original.name,
      parentId: original.parentId,
      tags: original.tags,
      children: original.children,
    );
  }

  /// Calcula o fator de movimento baseado no mouse
  static double calculateDelta(GizmoMode mode, String axis, double dx, double dy) {
    if (mode == GizmoMode.rotate) {
      const rotateSpeed = 0.8;
      if (axis == 'X') return dy * rotateSpeed;
      if (axis == 'Y') return dx * rotateSpeed;
      if (axis == 'Z') return -dx * rotateSpeed;
      return 0;
    } else {
      const speed = 0.05;
      if (axis == 'X') return dx * speed;
      if (axis == 'Y') return -dy * speed;
      if (axis == 'Z') return -dx * speed;
      return 0;
    }
  }
}
