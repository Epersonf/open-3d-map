import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import 'package:open_3d_mapper/domain/scene/game_object.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../../stores/tool_store.dart';
import '../gizmo_enums.dart';
import 'transform_strategy.dart';

class TranslateStrategy implements TransformStrategy {
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
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space) {
    var transform = original.getComponent<TransformComponent>();
    if (transform == null) return original;

    final position = three.Vector3(transform.position.x, transform.position.y, transform.position.z);
    three.Vector3 moveVector;

    switch (axis) {
      case GizmoAxis.x: moveVector = three.Vector3(1, 0, 0); break;
      case GizmoAxis.y: moveVector = three.Vector3(0, 1, 0); break;
      case GizmoAxis.z: moveVector = three.Vector3(0, 0, 1); break;
    }

    if (space == TransformSpace.local) {
      final euler = three.Euler(
        transform.rotation.x * (3.14159265359 / 180),
        transform.rotation.y * (3.14159265359 / 180),
        transform.rotation.z * (3.14159265359 / 180),
      );
      final quaternion = three.Quaternion().setFromEuler(euler);
      moveVector.applyQuaternion(quaternion);
    }

    final scaledMove = three.Vector3(
      moveVector.x * delta,
      moveVector.y * delta,
      moveVector.z * delta,
    );
    position.add(scaledMove);

    final store = ToolStore.instance;
    if (store.snapEnabled) {
      final step = store.snapIncrement;
      double _snap(double val) => step <= 0 ? val : (val / step).roundToDouble() * step;
      position.x = _snap(position.x);
      position.y = _snap(position.y);
      position.z = _snap(position.z);
    }

    return original.copyWithComponent(transform.copyWith(
      position: Vec3(x: position.x, y: position.y, z: position.z),
    ));
  }
}
