import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import 'package:open_3d_mapper/domain/scene/game_object/game_object.dart';
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
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space, three.Object3D? object3d) {
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
      // Global Rotation
      // R_new = R_delta * R_old
      // Porém, se tiver pai, o "Global Up" não é o "Parent Up".
      // Para correção total de rotação global com pai, seria necessário:
      // q_world = q_parent * q_local
      // q_world_new = q_delta_world * q_world
      // q_local_new = inv(q_parent) * q_world_new
      
      if (object3d != null && object3d.parent != null) {
         final parentQuat = three.Quaternion();
         object3d.parent!.getWorldQuaternion(parentQuat);
         
         // Convertemos o delta global para delta relativo ao pai
         final invParent = parentQuat.clone()..invert();
         // Transforma o eixo de rotação global para o espaço do pai
         axisVector.applyQuaternion(invParent);
         deltaQuat.setFromAxisAngle(axisVector, deltaRad);
         
         // Aplica à rotação local (que é relativa ao pai)
         currentQuat.premultiply(deltaQuat);
      } else {
         currentQuat.premultiply(deltaQuat);
      }
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
