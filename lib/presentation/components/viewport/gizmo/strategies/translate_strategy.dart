import '../../../../../domain/scene/game_object.dart';
import '../../../../../domain/scene/transform.dart' as domain;
import '../gizmo_enums.dart';
import 'transform_strategy.dart';

class TranslateStrategy implements TransformStrategy {
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
    double x = original.transform.position.x;
    double y = original.transform.position.y;
    double z = original.transform.position.z;

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
        position: domain.Vec3(x: x, y: y, z: z),
        rotation: original.transform.rotation,
        scale: original.transform.scale,
      ),
      tags: original.tags,
      children: original.children,
    );
  }
}
