import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';
import '../../../../domain/scene/visual_component.dart';

class SceneObject {
  final String id;
  GameObject gameObject;
  three.Object3D? object3d;
  
  // Cache para detectar mudanças
  VisualComponent cachedVisual;

  SceneObject({
    required this.id,
    required this.gameObject,
    this.object3d,
  }) : cachedVisual = gameObject.visual;

  void disposeVisual() {
    object3d?.removeFromParent();
    // Limpar geometrias/materiais se necessário
  }

  /// Troca o objeto 3D subjacente mantendo a posição na cena
  void replaceObject3d(three.Object3D? newObject, three.Scene scene) {
    three.Object3D? oldParent;
    
    if (object3d != null) {
      oldParent = object3d!.parent;
      object3d!.removeFromParent();
      
      final children = List<three.Object3D>.from(object3d!.children);
      for(final child in children) {
        if (child.userData['gameObjectId'] != null) {
           newObject?.add(child);
        }
      }
    }

    object3d = newObject;

    if (object3d != null) {
      object3d!.userData['gameObjectId'] = id;
      object3d!.name = gameObject.name;
      
      if (oldParent != null) {
        oldParent.add(object3d!);
      } else {
        scene.add(object3d!);
      }
      
      updateTransform();
    }
  }

  void updateTransform() {
    if (object3d == null) return;
    object3d!.position.setValues(
      gameObject.transform.position.x,
      gameObject.transform.position.y,
      gameObject.transform.position.z,
    );

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
}
