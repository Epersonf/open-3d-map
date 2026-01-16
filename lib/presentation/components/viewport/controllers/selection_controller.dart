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
    // CORREÇÃO: Passamos o tamanho do box explicitamente
    _updateMouseCoordinates(offset, box.size);
  }

  void _updateMousePositionFromTap(TapDownDetails details, BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final offset = box.globalToLocal(details.globalPosition);
    // CORREÇÃO: Passamos o tamanho do box explicitamente
    _updateMouseCoordinates(offset, box.size);
  }

  // CORREÇÃO: O método agora aceita o Size do container
  void _updateMouseCoordinates(Offset offset, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Normalização Device Coordinates (NDC):
    // X vai de -1 a +1
    // Y vai de +1 a -1 (Invertido)
    // Usamos size.width/height em vez de threeJs.width/height para garantir precisão
    _mouse.x = (offset.dx / size.width) * 2 - 1;
    _mouse.y = -(offset.dy / size.height) * 2 + 1;
  }

  void _performRaycast() {
    _raycaster.setFromCamera(_mouse, threeJs.camera);

    final List<three.Object3D> intersectedObjects = [];
    for (final sceneObject in sceneManager.sceneObjects.values) {
      final object3d = sceneObject.object3d;
      if (object3d != null) {
        object3d.traverse((object) {
          // Aceitar tanto Mesh quanto Sprite para detecção de clique
          if (object is three.Mesh || object is three.Sprite) {
            intersectedObjects.add(object);
          }
        });
      }
    }

    final intersects = _raycaster.intersectObjects(intersectedObjects, true);

    if (intersects.isNotEmpty) {
      // O primeiro item da lista é sempre o mais próximo da câmera
      _handleIntersection(intersects.first.object!);
    } else {
      _handleNoIntersection();
    }
  }

  void _handleIntersection(three.Object3D clickedObject) {
    var currentObject = clickedObject;
    
    // Sobe na hierarquia até achar o ID do GameObject
    // Adicionamos um limite de segurança (currentObject.parent != null) para não crashar na raiz
    while (currentObject.userData['gameObjectId'] == null && currentObject.parent != null) {
      currentObject = currentObject.parent!;
    }

    if (currentObject.userData['gameObjectId'] != null) {
      final gameObjectId = currentObject.userData['gameObjectId'] as String;
      final gameObject = ProjectStore.instance.findGameObjectById(gameObjectId);

      if (gameObject != null) {
        SelectionStore.instance.select(gameObject);
        // Não precisamos chamar highlightObject aqui manualmente se o Reaction no Viewport já faz isso
        // Mas mal não faz manter
        // sceneManager.highlightObject(gameObject.id); 
        return;
      }
    }
    
    _handleNoIntersection();
  }

  void _handleNoIntersection() {
    SelectionStore.instance.clear();
    // sceneManager.highlightObject(null); // Idem acima
  }
}