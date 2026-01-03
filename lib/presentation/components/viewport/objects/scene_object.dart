import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';

class SceneObject {
  final String id;
  GameObject gameObject;
  three.Object3D? object3d;
  String? assetId;

  SceneObject({
    required this.id,
    required this.gameObject,
    this.object3d,
    this.assetId,
  });

  void updateTransform() {
    if (object3d == null) return;

    object3d!.position.setValues(
      gameObject.transform.position.x,
      gameObject.transform.position.y,
      gameObject.transform.position.z,
    );

    // Converter graus para radianos
    object3d!.rotation.set(
      gameObject.transform.rotation.x * (3.14159265359 / 180),
      gameObject.transform.rotation.y * (3.14159265359 / 180),
      gameObject.transform.rotation.z * (3.14159265359 / 180),
    );

    object3d!.scale.setValues(
      gameObject.transform.scale.x,
      gameObject.transform.scale.y,
      gameObject.transform.scale.z,
    );
  }

  void dispose() {
    object3d?.removeFromParent();
    object3d = null;
    // Nota: three_js não requer disposição explícita de Object3D
  }
}
