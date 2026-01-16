import 'package:flutter/material.dart'; // Necessário para Icons.*
import 'package:three_js/three_js.dart' as three;
import '../../../../core/utils/icon_texture_generator.dart'; // Importe o novo utilitário
import '../../../../domain/scene/game_object.dart';
import '../../../../domain/scene/visual_component.dart';
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

  /// Verifica se o visual mudou e recria o objeto 3D se necessário
  Future<void> updateSceneObject(GameObject gameObject) async {
    final sceneObject = _sceneObjects[gameObject.id];
    if (sceneObject != null) {
      final oldVisual = sceneObject.cachedVisual;
      final newVisual = gameObject.visual;

      bool visualChanged = oldVisual.type != newVisual.type ||
                           oldVisual.assetId != newVisual.assetId ||
                           oldVisual.iconName != newVisual.iconName;

      if (visualChanged) {
         // Remover visual antigo
         sceneObject.disposeVisual();
         
         // Carregar novo visual
         final newObj3d = await _createVisualRepresentation(gameObject);
         sceneObject.replaceObject3d(newObj3d, scene);
         sceneObject.cachedVisual = newVisual;
      }

      sceneObject.gameObject = gameObject;
      sceneObject.updateTransform();
      _updateParentRelationship(sceneObject, gameObject.parentId);
    }
  }

  // Lógica extraída de Viewport._createSceneObject e movida para cá
  Future<three.Object3D?> _createVisualRepresentation(GameObject gameObject) async {
    final visual = gameObject.visual;

    if (visual.type == VisualType.none) {
      final group = three.Group();
      final material = three.MeshBasicMaterial();
      material.color = three.Color.fromHex32(0x444444);
      material.wireframe = true;
      final helper = three.Mesh(
        three.BoxGeometry(0.5, 0.5, 0.5),
        material,
      );
      group.add(helper);
      return group;
    }

    if (visual.type == VisualType.mesh && visual.assetId != null) {
       // Lógica existente de carregar Mesh via ModelManager
       final model = await modelManager.loadModel(visual.assetId!, '', '');
       if (model != null) return model.clone();
    }

    if (visual.type == VisualType.icon && visual.iconName != null) {
       return await _createIconSprite(visual.iconName!);
    }

    return three.Group(); // Fallback
  }

  Future<three.Object3D> _createIconSprite(String iconName) async {
    // 1. Mapeamento de String -> IconData
    IconData iconData = Icons.help_outline; // Default
    switch (iconName) {
      case 'light':
        iconData = Icons.lightbulb;
        break;
      case 'camera':
        iconData = Icons.videocam;
        break;
      case 'spawn':
        iconData = Icons.flag;
        break;
      case 'enemy':
        iconData = Icons.bug_report;
        break;
    }

    // 2. Gerar textura em memória (com padding interno via iconScale)
    final texture = await IconTextureGenerator.createTextureFromIcon(
      iconData,
      size: 128, // Qualidade da textura
      color: Colors.white, // Desenhar em branco para permitir tintura posterior
    );

    final material = three.SpriteMaterial();
    material.map = texture;
    // A cor base branca permite que a textura apareça original. 
    // Se mudarmos essa cor, ela tinge o ícone (útil para seleção).
    material.color = three.Color.fromHex32(0xFFFFFF);
    material.transparent = true;
    material.alphaTest = 0.5; // Melhora o recorte do ícone

    final sprite = three.Sprite(material);
    // Escala fixa para o ícone no mundo 3D
    sprite.scale.setValues(1.5, 1.5, 1.5);
    
    return sprite;
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
