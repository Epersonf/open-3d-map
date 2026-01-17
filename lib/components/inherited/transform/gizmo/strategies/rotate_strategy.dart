import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import 'package:open_3d_mapper/domain/scene/game_object.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../../stores/tool_store.dart';
import '../gizmo_enums.dart';
import 'transform_strategy.dart';

class RotateStrategy implements TransformStrategy {
  @override
  double calculateDelta(GizmoAxis axis, double dx, double dy) {
    const rotateSpeed = 0.8;
    switch (axis) {
      case GizmoAxis.x: return dy * rotateSpeed;
      case GizmoAxis.y: return dx * rotateSpeed;
      case GizmoAxis.z: return -dx * rotateSpeed;
    }
  }

  @override
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space) {
    var transform = original.getComponent<TransformComponent>();
    if (transform == null) return original;

    final rad = 3.14159265359 / 180;
    final currentEuler = three.Euler(transform.rotation.x * rad, transform.rotation.y * rad, transform.rotation.z * rad, three.RotationOrders.xyz);
    final currentQuat = three.Quaternion().setFromEuler(currentEuler);

    final deltaRad = delta * rad;
    final deltaQuat = three.Quaternion();
    three.Vector3 axisVector;

    switch (axis) {
      case GizmoAxis.x: axisVector = three.Vector3(1, 0, 0); break;
      case GizmoAxis.y: axisVector = three.Vector3(0, 1, 0); break;
      case GizmoAxis.z: axisVector = three.Vector3(0, 0, 1); break;
    }

    deltaQuat.setFromAxisAngle(axisVector, deltaRad);

    if (space == TransformSpace.local) {
      currentQuat.multiply(deltaQuat);
    } else {
      currentQuat.premultiply(deltaQuat);
    }

    final newEuler = three.Euler().setFromQuaternion(currentQuat, three.RotationOrders.xyz);

    return original.copyWithComponent(transform.copyWith(
      rotation: Vec3(
        x: newEuler.x * (180 / 3.14159265359),
        y: newEuler.y * (180 / 3.14159265359),
        z: newEuler.z * (180 / 3.14159265359),
      ),
    ));
  }
}
