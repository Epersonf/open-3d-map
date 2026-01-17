import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';

class SceneObject {
  final String id;
  GameObject gameObject;
  three.Object3D? object3d; // É sempre um Group container agora

  SceneObject({
    required this.id,
    required this.gameObject,
    this.object3d,
  });

  void updateTransform() {
    if (object3d == null) return;
    var transform = gameObject.getComponent<TransformComponent>();
    if (transform == null) return;
    object3d!.position.setValues(transform.position.x, transform.position.y, transform.position.z);
    object3d!.rotation.set(
      transform.rotation.x * (3.14159265359 / 180),
      transform.rotation.y * (3.14159265359 / 180),
      transform.rotation.z * (3.14159265359 / 180),
    );
    object3d!.scale.setValues(transform.scale.x, transform.scale.y, transform.scale.z);
  }
}
