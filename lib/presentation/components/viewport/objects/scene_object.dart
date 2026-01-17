import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object/game_object.dart';

class SceneObject {
  final String id;
  GameObject gameObject;
  three.Object3D? object3d;

  SceneObject({
    required this.id,
    required this.gameObject,
    this.object3d,
  });
}
