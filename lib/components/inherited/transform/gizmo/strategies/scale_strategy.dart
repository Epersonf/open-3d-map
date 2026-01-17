import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import 'package:open_3d_mapper/domain/scene/game_object/game_object.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../../stores/tool_store.dart';
import '../gizmo_enums.dart';
import 'transform_strategy.dart';

class ScaleStrategy implements TransformStrategy {
  @override
  double calculateDelta(GizmoAxis axis, double dx, double dy) {
    const speed = 0.05;
    switch (axis) {
      case GizmoAxis.x: return dx * speed;
      case GizmoAxis.y: return -dy * speed;
      case GizmoAxis.z: return -dx * speed;
    }
  }

  @override
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space, three.Object3D? object3d) {
    var transform = original.getComponent<TransformComponent>();
    if (transform == null) return original;
    
    double sx = transform.scale.x;
    double sy = transform.scale.y;
    double sz = transform.scale.z;

    if (space == TransformSpace.local) {
      switch (axis) {
        case GizmoAxis.x: sx += delta; break;
        case GizmoAxis.y: sy += delta; break;
        case GizmoAxis.z: sz += delta; break;
      }
    } else {
      three.Vector3 globalMove;
      switch (axis) {
        case GizmoAxis.x: globalMove = three.Vector3(1, 0, 0); break;
        case GizmoAxis.y: globalMove = three.Vector3(0, 1, 0); break;
        case GizmoAxis.z: globalMove = three.Vector3(0, 0, 1); break;
      }
      // scale the direction by delta
      globalMove = three.Vector3(globalMove.x * delta, globalMove.y * delta, globalMove.z * delta);

      final euler = three.Euler(transform.rotation.x * (3.14159 / 180), transform.rotation.y * (3.14159 / 180), transform.rotation.z * (3.14159 / 180));
      final quaternion = three.Quaternion().setFromEuler(euler)..invert();
      globalMove.applyQuaternion(quaternion);

      sx += globalMove.x;
      sy += globalMove.y;
      sz += globalMove.z;
    }

    if (sx < 0.01) sx = 0.01;
    if (sy < 0.01) sy = 0.01;
    if (sz < 0.01) sz = 0.01;

    return original.copyWithComponent(transform.copyWith(
      scale: Vec3(x: sx, y: sy, z: sz),
    ));
  }
}
