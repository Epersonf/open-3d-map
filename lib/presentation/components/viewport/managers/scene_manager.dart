import 'package:open_3d_mapper/components/inherited/visual/visual_component.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';
import '../../../../domain/asset/asset.dart';
import '../../../../stores/project_store.dart';
import '../objects/scene_object.dart';
import 'model_manager.dart';

// Imports da nova arquitetura de renderização
import '../rendering/renderer_factory.dart';

class SceneManager {
  final three.Scene scene;
  final ModelManager modelManager;
  final Map<String, SceneObject> _sceneObjects = {};

  late final RendererFactory _rendererFactory;

  SceneManager({
    required this.scene,
    required this.modelManager,
  }) {
    _rendererFactory = RendererFactory(
      modelManager: modelManager,
      projectPath: ProjectStore.instance.projectPath ?? '',
    );
  }

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

  Future<void> updateSceneObject(GameObject gameObject) async {
    final sceneObject = _sceneObjects[gameObject.id];
    if (sceneObject != null) {
      final oldVisual = sceneObject.cachedVisual;
      final newVisual = gameObject.getComponent<VisualComponent>();
      if (newVisual == null) return;

      bool visualChanged = oldVisual.type != newVisual.type ||
          oldVisual.assetId != newVisual.assetId ||
          oldVisual.iconName != newVisual.iconName;

      if (visualChanged) {
        sceneObject.disposeVisual();
        final newObj3d = await _createVisualRepresentation(gameObject);
        sceneObject.replaceObject3d(newObj3d, scene);
        sceneObject.cachedVisual = newVisual;
      }

      sceneObject.gameObject = gameObject;
      sceneObject.updateTransform();
      _updateParentRelationship(sceneObject, gameObject.parentId);
    }
  }

  Future<three.Object3D?> _createVisualRepresentation(GameObject gameObject) async {
    var visualComp = gameObject.getComponent<VisualComponent>();
    if (visualComp == null) {
      return null;
    }
    // Mesh handling: resolve Asset path via ProjectStore then use ModelManager
    if (visualComp.type == VisualType.mesh && visualComp.assetId != null) {
      final project = ProjectStore.instance.project;
      final asset = project?.assets.firstWhere(
        (a) => a.id == visualComp.assetId,
        orElse: () => Asset(id: '', path: '', type: ''),
      );

      if (asset != null && asset.path.isNotEmpty) {
        final model = await modelManager.loadModel(
          asset.id,
          ProjectStore.instance.projectPath ?? '',
          asset.path,
        );
        if (model != null) return model.clone();
      }
    }

    // Delegate to renderer factory for icons/empty/fallback
    final renderer = _rendererFactory.getRenderer(visualComp.type);
    return await renderer.render(gameObject);
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
    sceneObject?.disposeVisual();
  }

  void clear() {
    for (final sceneObject in _sceneObjects.values) {
      sceneObject.disposeVisual();
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