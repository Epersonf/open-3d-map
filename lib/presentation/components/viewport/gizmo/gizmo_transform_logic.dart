import '../../../../domain/scene/game_object.dart';
import '../../../../domain/scene/transform.dart' as domain;
import '../../../../stores/tool_store.dart';

class GizmoTransformLogic {
  /// Calcula e retorna um NOVO GameObject com as transformações aplicadas
  static GameObject applyTransform({
    required GameObject original,
    required GizmoMode mode,
    required String axis,
    required double delta,
  }) {
    double px = original.transform.position.x;
    double py = original.transform.position.y;
    double pz = original.transform.position.z;

    double rx = original.transform.rotation.x;
    double ry = original.transform.rotation.y;
    double rz = original.transform.rotation.z;

    double sx = original.transform.scale.x;
    double sy = original.transform.scale.y;
    double sz = original.transform.scale.z;

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
      assetId: original.assetId,
      transform: domain.Transform(
        position: domain.Vec3(x: px, y: py, z: pz),
        rotation: domain.Vec3(x: rx, y: ry, z: rz),
        scale: domain.Vec3(x: sx, y: sy, z: sz),
      ),
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
