import 'package:three_js/three_js.dart' as three;
import '../../../../../domain/scene/game_object.dart';
import '../../../../../domain/scene/transform.dart' as domain;
import '../../../../../stores/tool_store.dart';
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
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space) {
    final position = three.Vector3(
      original.transform.position.x,
      original.transform.position.y,
      original.transform.position.z,
    );

    three.Vector3 moveVector;
    switch (axis) {
      case GizmoAxis.x:
        moveVector = three.Vector3(1, 0, 0);
        break;
      case GizmoAxis.y:
        moveVector = three.Vector3(0, 1, 0);
        break;
      case GizmoAxis.z:
        moveVector = three.Vector3(0, 0, 1);
        break;
    }

    if (space == TransformSpace.local) {
      final euler = three.Euler(
        original.transform.rotation.x * (3.14159265359 / 180),
        original.transform.rotation.y * (3.14159265359 / 180),
        original.transform.rotation.z * (3.14159265359 / 180),
      );
      final quaternion = three.Quaternion().setFromEuler(euler);
      moveVector.applyQuaternion(quaternion);
    }

    moveVector = three.Vector3(
      moveVector.x * delta,
      moveVector.y * delta,
      moveVector.z * delta,
    );
    position.add(moveVector);

    return GameObject(
      id: original.id,
      name: original.name,
      parentId: original.parentId,
      assetId: original.assetId,
      transform: domain.Transform(
        position: domain.Vec3(x: position.x, y: position.y, z: position.z),
        rotation: original.transform.rotation,
        scale: original.transform.scale,
      ),
      tags: original.tags,
      children: original.children,
    );
  }
}
