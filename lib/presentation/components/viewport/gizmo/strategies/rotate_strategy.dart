import 'package:three_js/three_js.dart' as three;
import '../../../../../domain/scene/game_object.dart';
import '../../../../../domain/scene/transform.dart' as domain;
import '../../../../../stores/tool_store.dart';
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
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space) {
    final currentEuler = three.Euler(
      original.transform.rotation.x * (3.14159 / 180),
      original.transform.rotation.y * (3.14159 / 180),
      original.transform.rotation.z * (3.14159 / 180),
      three.RotationOrders.yxz,
    );
    final currentQuat = three.Quaternion().setFromEuler(currentEuler);

    final deltaRad = delta * (3.14159 / 180);
    final deltaQuat = three.Quaternion();

    three.Vector3 axisVector;
    switch (axis) {
      case GizmoAxis.x:
        axisVector = three.Vector3(1, 0, 0);
        break;
      case GizmoAxis.y:
        axisVector = three.Vector3(0, 1, 0);
        break;
      case GizmoAxis.z:
        axisVector = three.Vector3(0, 0, 1);
        break;
    }

    deltaQuat.setFromAxisAngle(axisVector, deltaRad);

    if (space == TransformSpace.local) {
      currentQuat.multiply(deltaQuat);
    } else {
      currentQuat.premultiply(deltaQuat);
    }

    final newEuler = three.Euler().setFromQuaternion(currentQuat, three.RotationOrders.yxz);

    return GameObject(
      id: original.id,
      name: original.name,
      parentId: original.parentId,
      assetId: original.assetId,
      transform: domain.Transform(
        position: original.transform.position,
        rotation: domain.Vec3(
          x: newEuler.x * (180 / 3.14159),
          y: newEuler.y * (180 / 3.14159),
          z: newEuler.z * (180 / 3.14159),
        ),
        scale: original.transform.scale,
      ),
      tags: original.tags,
      children: original.children,
    );
  }
}
