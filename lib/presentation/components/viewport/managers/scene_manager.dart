import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';
import '../../../../domain/scene/scene_context.dart';
import '../../../../stores/project_store.dart';
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

    // initialize components when added
    _initializeComponents(sceneObject);
  }

  Future<void> updateSceneObject(GameObject gameObject) async {
    SceneObject? sceneObject = _sceneObjects[gameObject.id];
    if (sceneObject == null) {
      // create container if missing
      final group = three.Group();
      group.name = gameObject.name;
      group.userData['gameObjectId'] = gameObject.id;

      sceneObject = SceneObject(id: gameObject.id, gameObject: gameObject, object3d: group);
      _sceneObjects[gameObject.id] = sceneObject;
      scene.add(group);
      _initializeComponents(sceneObject);
    } else {
      // hot-reload components if the gameObject reference changed
      if (sceneObject.gameObject != gameObject) {
        _disposeComponents(sceneObject);
        sceneObject.gameObject = gameObject;
        sceneObject.object3d!.name = gameObject.name;
        _initializeComponents(sceneObject);
      }
    }

    // update transform and parent
    sceneObject.updateTransform();
    _updateParentRelationship(sceneObject, gameObject.parentId);
  }

  void _initializeComponents(SceneObject sceneObject) {
    if (sceneObject.object3d == null) return;

    final context = SceneContext(
      parent: sceneObject.object3d!,
      scene: scene,
      modelManager: modelManager,
      projectStore: ProjectStore.instance,
    );

    for (final component in sceneObject.gameObject.components) {
      try {
        component.onStart(context);
      } catch (e) {
        // ignore component errors to keep editor stable
      }
    }
  }

  void _disposeComponents(SceneObject sceneObject) {
    if (sceneObject.object3d == null) return;

    final context = SceneContext(
      parent: sceneObject.object3d!,
      scene: scene,
      modelManager: modelManager,
      projectStore: ProjectStore.instance,
    );

    for (final component in sceneObject.gameObject.components) {
      try {
        component.onDestroy(context);
      } catch (e) {
        // ignore
      }
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
    if (sceneObject != null) {
      _disposeComponents(sceneObject);
      sceneObject.object3d?.removeFromParent();
    }
  }

  void clear() {
    for (final sceneObject in _sceneObjects.values) {
      _disposeComponents(sceneObject);
      sceneObject.object3d?.removeFromParent();
    }
    _sceneObjects.clear();
  }

  void highlightObject(String? gameObjectId) {
    for (final sceneObject in _sceneObjects.values) {
      _removeHighlight(sceneObject);
    }

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
      if (object is three.Sprite) {
        object.material?.color = three.Color.fromHex32(0xFFFFFF);
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
      if (object is three.Sprite) {
        object.material?.color = three.Color.fromHex32(0xFFAA00);
      }
    });
  }
}