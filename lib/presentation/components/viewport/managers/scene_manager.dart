import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';
import '../../../../domain/scene/scene_context.dart';
import '../../../../stores/project_store.dart';
import '../objects/scene_object.dart';
import 'model_manager.dart';

class SceneManager {
  final three.Scene scene;
  final three.Camera camera;
  final ModelManager modelManager;
  final Map<String, SceneObject> _sceneObjects = {};

  SceneManager({
    required this.scene,
    required this.camera,
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
    final newGameObject = gameObject;
    SceneObject? sceneObject = _sceneObjects[newGameObject.id];

    if (sceneObject == null) {
      // Initial creation
      final group = three.Group();
      group.name = newGameObject.name;
      group.userData['gameObjectId'] = newGameObject.id;

      sceneObject = SceneObject(id: newGameObject.id, gameObject: newGameObject, object3d: group);
      _sceneObjects[newGameObject.id] = sceneObject;
      scene.add(group);

      _initializeComponents(sceneObject);
    } else {
      // DIFF + Smart update
      final oldGameObject = sceneObject.gameObject;
      sceneObject.gameObject = newGameObject;
      sceneObject.object3d!.name = newGameObject.name;

      final context = _createContext(sceneObject);

      final oldComps = {for (var c in oldGameObject.components) c.id: c};

      for (final newComp in newGameObject.components) {
        final oldComp = oldComps[newComp.id];

        if (oldComp != null) {
          bool updated = false;
          try {
            if (oldComp.runtimeType == newComp.runtimeType) {
              updated = newComp.onDidUpdate(oldComp, context);
            }
          } catch (e) {
            // ignore
          }

          if (!updated) {
            try { oldComp.onDestroy(context); } catch (_) {}
            try { newComp.onStart(context); } catch (_) {}
          }

          oldComps.remove(newComp.id);
        } else {
          // New component
          try { newComp.onStart(context); } catch (_) {}
        }

        // preserve selection visual state
        if (_currentSelectionId == newGameObject.id) {
          try { newComp.onSelected(context); } catch (_) {}
        }
      }

      // Destroy any removed components
      for (final removed in oldComps.values) {
        try { removed.onDestroy(context); } catch (_) {}
      }
    }

    // Parenting handled below; TransformComponent is responsible for applying transforms
    _updateParentRelationship(sceneObject, newGameObject.parentId);
  }

  void _initializeComponents(SceneObject sceneObject) {
    if (sceneObject.object3d == null) return;
    final context = _createContext(sceneObject);

    for (final component in sceneObject.gameObject.components) {
      try { component.onStart(context); } catch (_) {}
    }
  }

  SceneContext _createContext(SceneObject sceneObject) {
    return SceneContext(
      parent: sceneObject.object3d!,
      scene: scene,
      camera: camera,
      modelManager: modelManager,
      projectStore: ProjectStore.instance,
    );
  }

  void _disposeComponents(SceneObject sceneObject) {
    if (sceneObject.object3d == null) return;

    final context = SceneContext(
      parent: sceneObject.object3d!,
      scene: scene,
      camera: camera,
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

  /// Método chamado a cada frame pelo Viewport (Game Loop)
  void onUpdate(double dt) {
    for (final sceneObject in _sceneObjects.values) {
      if (sceneObject.object3d == null) continue;

      final context = _createContext(sceneObject);

      for (final component in sceneObject.gameObject.components) {
        try {
          component.onUpdate(context, dt);
        } catch (e) {
          // Falha em um componente não deve quebrar o loop de atualização
          print('Erro no onUpdate do componente ${component.id}: $e');
        }
      }
    }
  }
  // --- Selection delegation ---
  // Track current selection so we can notify old/new components
  String? _currentSelectionId;

  /// Called by the Viewport when selection changes
  void onSelectionChanged(String? newId) {
    // Unselect previous
    if (_currentSelectionId != null && _currentSelectionId != newId) {
      final oldObj = _sceneObjects[_currentSelectionId];
      if (oldObj != null) {
        _notifySelectionChange(oldObj, false);
      }
    }

    _currentSelectionId = newId;

    // Select new
    if (newId != null) {
      final newObj = _sceneObjects[newId];
      if (newObj != null) {
        _notifySelectionChange(newObj, true);
      }
    }
  }

  void _notifySelectionChange(SceneObject sceneObject, bool isSelected) {
    if (sceneObject.object3d == null) return;
    final context = SceneContext(
      parent: sceneObject.object3d!,
      scene: scene,
      camera: camera,
      modelManager: modelManager,
      projectStore: ProjectStore.instance,
    );

    for (final component in sceneObject.gameObject.components) {
      try {
        if (isSelected) {
          component.onSelected(context);
        } else {
          component.onDeselected(context);
        }
      } catch (_) {}
    }
  }
}