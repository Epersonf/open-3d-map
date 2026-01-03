import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';
import '../objects/scene_object.dart';
import 'model_manager.dart';

class SceneManager {
  final three.Scene scene;
  final ModelManager modelManager;
  final Map<String, SceneObject> _sceneObjects = {};

  SceneManager({
    required this.scene,
    required this.modelManager,
  });

  SceneObject? getSceneObject(String id) => _sceneObjects[id];
  
  Map<String, SceneObject> get sceneObjects => Map.unmodifiable(_sceneObjects);

  void addSceneObject(SceneObject sceneObject, {three.Object3D? parent}) {
    _sceneObjects[sceneObject.id] = sceneObject;
    
    if (sceneObject.object3d != null) {
      if (parent != null) {
        parent.add(sceneObject.object3d!);
      } else {
        scene.add(sceneObject.object3d!);
      }
    }
  }

  void updateSceneObject(GameObject gameObject) {
    final sceneObject = _sceneObjects[gameObject.id];
    if (sceneObject != null) {
      sceneObject.gameObject = gameObject;
      sceneObject.updateTransform();
      _updateParentRelationship(sceneObject, gameObject.parentId);
    }
  }

  void _updateParentRelationship(SceneObject sceneObject, String? parentId) {
    final object3d = sceneObject.object3d;
    if (object3d == null) return;

    three.Object3D? newParent;
    if (parentId != null) {
      newParent = _sceneObjects[parentId]?.object3d;
    }

    final currentParent = object3d.parent;
    if (currentParent != newParent) {
      object3d.removeFromParent();
      if (newParent != null) {
        newParent.add(object3d);
      } else {
        scene.add(object3d);
      }
    }
  }

  void removeSceneObject(String id) {
    final sceneObject = _sceneObjects.remove(id);
    sceneObject?.dispose();
  }

  void clear() {
    for (final sceneObject in _sceneObjects.values) {
      sceneObject.dispose();
    }
    _sceneObjects.clear();
  }

  void highlightObject(String? gameObjectId) {
    // Remover destaque de todos os objetos
    for (final sceneObject in _sceneObjects.values) {
      _removeHighlight(sceneObject);
    }

    // Destacar objeto selecionado
    if (gameObjectId != null) {
      final sceneObject = _sceneObjects[gameObjectId];
      if (sceneObject != null) {
        _applyHighlight(sceneObject);
      }
    }
  }

  void _removeHighlight(SceneObject sceneObject) {
    final object3d = sceneObject.object3d;
    if (object3d == null) return;

    object3d.traverse((object) {
      if (object is three.Mesh) {
        if (object.material is three.MeshStandardMaterial) {
          final material = object.material as three.MeshStandardMaterial;
          material.emissive = three.Color.fromHex32(0x000000);
          material.emissiveIntensity = 0.0;
        }
      }
    });
  }

  void _applyHighlight(SceneObject sceneObject) {
    final object3d = sceneObject.object3d;
    if (object3d == null) return;

    object3d.traverse((object) {
      if (object is three.Mesh) {
        if (object.material is three.MeshStandardMaterial) {
          final material = object.material as three.MeshStandardMaterial;
          material.emissive = three.Color.fromHex32(0x444400);
          material.emissiveIntensity = 0.5;
        }
      }
    });
  }
}
