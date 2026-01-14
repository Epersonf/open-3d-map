import '../../../../../domain/scene/game_object.dart';
import '../../../../../domain/scene/transform.dart' as domain;
import '../gizmo_enums.dart';
import 'transform_strategy.dart';

class ScaleStrategy implements TransformStrategy {
  @override
  double calculateDelta(GizmoAxis axis, double dx, double dy) {
    const speed = 0.05;
    switch (axis) {
      case GizmoAxis.x:
        return dx * speed;
      case GizmoAxis.y:
        return -dy * speed;
      case GizmoAxis.z:
        return -dx * speed;
    }
  }

  @override
  GameObject apply(GameObject original, GizmoAxis axis, double delta) {
    double x = original.transform.scale.x;
    double y = original.transform.scale.y;
    double z = original.transform.scale.z;

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

    if (x < 0.01) x = 0.01;
    if (y < 0.01) y = 0.01;
    if (z < 0.01) z = 0.01;

    return GameObject(
      id: original.id,
      name: original.name,
      parentId: original.parentId,
      assetId: original.assetId,
      transform: domain.Transform(
        position: original.transform.position,
        rotation: original.transform.rotation,
        scale: domain.Vec3(x: x, y: y, z: z),
      ),
      tags: original.tags,
      children: original.children,
    );
  }
}
