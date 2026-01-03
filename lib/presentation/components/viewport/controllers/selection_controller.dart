import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../managers/scene_manager.dart';

class SelectionController {
  final three.ThreeJS threeJs;
  final SceneManager sceneManager;
  final three.Raycaster _raycaster = three.Raycaster();
  final three.Vector2 _mouse = three.Vector2(0, 0);

  SelectionController({
    required this.threeJs,
    required this.sceneManager,
  });

  void onPointerMove(PointerMoveEvent event, BuildContext context) {
    _updateMousePosition(event, context);
  }

  void onTapDown(TapDownDetails details, BuildContext context) {
    _updateMousePositionFromTap(details, context);
    _performRaycast();
  }

  void _updateMousePosition(PointerMoveEvent event, BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final offset = box.globalToLocal(event.position);
    _updateMouseCoordinates(offset);
  }

  void _updateMousePositionFromTap(TapDownDetails details, BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final offset = box.globalToLocal(details.globalPosition);
    _updateMouseCoordinates(offset);
  }

  void _updateMouseCoordinates(Offset offset) {
    _mouse.x = (offset.dx / threeJs.width) * 2 - 1;
    _mouse.y = -(offset.dy / threeJs.height) * 2 + 1;
  }

  void _performRaycast() {
    _raycaster.setFromCamera(_mouse, threeJs.camera);

    // Coletar todos os objetos clicáveis
    final List<three.Object3D> intersectedObjects = [];
    for (final sceneObject in sceneManager.sceneObjects.values) {
      final object3d = sceneObject.object3d;
      if (object3d != null) {
        object3d.traverse((object) {
          if (object is three.Mesh) {
            intersectedObjects.add(object);
          }
        });
      }
    }

    // Encontrar interseções
    final intersects = _raycaster.intersectObjects(intersectedObjects, true);

    if (intersects.isNotEmpty) {
      _handleIntersection(intersects.first.object!);
    } else {
      _handleNoIntersection();
    }
  }

  void _handleIntersection(three.Object3D clickedObject) {
    // Subir na hierarquia até encontrar um objeto com gameObjectId
    var currentObject = clickedObject;
    while (currentObject.userData['gameObjectId'] == null) {
      currentObject = currentObject.parent!;
    }

    if (currentObject.userData['gameObjectId'] != null) {
      final gameObjectId = currentObject.userData['gameObjectId'] as String;
      final gameObject = ProjectStore.instance.findGameObjectById(gameObjectId);

      if (gameObject != null) {
        SelectionStore.instance.select(gameObject);
        sceneManager.highlightObject(gameObject.id);
        return;
      }
    }
    
    _handleNoIntersection();
  }

  void _handleNoIntersection() {
    SelectionStore.instance.clear();
    sceneManager.highlightObject(null);
  }
}
