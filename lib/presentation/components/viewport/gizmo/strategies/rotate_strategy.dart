import '../../../../../domain/scene/game_object.dart';
import '../../../../../domain/scene/transform.dart' as domain;
import '../gizmo_enums.dart';
import 'transform_strategy.dart';

class RotateStrategy implements TransformStrategy {
  @override
  double calculateDelta(GizmoAxis axis, double dx, double dy) {
    const rotateSpeed = 0.8;
    switch (axis) {
      case GizmoAxis.x:
        return dy * rotateSpeed;
      case GizmoAxis.y:
        return dx * rotateSpeed;
      case GizmoAxis.z:
        return -dx * rotateSpeed;
    }
  }

  @override
  GameObject apply(GameObject original, GizmoAxis axis, double delta) {
    double x = original.transform.rotation.x;
    double y = original.transform.rotation.y;
    double z = original.transform.rotation.z;

    switch (axis) {
      case GizmoAxis.x:
        x += delta;
        break;
      case GizmoAxis.y:
        y += delta;
        break;
      case GizmoAxis.z:
        z += delta;
        break;
    }

    return GameObject(
      id: original.id,
      name: original.name,
      parentId: original.parentId,
      assetId: original.assetId,
      transform: domain.Transform(
        position: original.transform.position,
        rotation: domain.Vec3(x: x, y: y, z: z),
        scale: original.transform.scale,
      ),
      tags: original.tags,
      children: original.children,
    );
  }
}
