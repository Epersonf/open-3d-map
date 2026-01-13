import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../../stores/tool_store.dart';
import '../gizmo/gizmo_loader.dart';
import '../gizmo/gizmo_transform_logic.dart';

class GizmoController {
  final three.ThreeJS threeJs;
  
  // Modelos individuais para cada modo
  three.Object3D? _moveGizmo;
  three.Object3D? _rotateGizmo;
  three.Object3D? _scaleGizmo;
  
  three.Object3D? get _activeGizmo {
    switch (ToolStore.instance.activeMode) {
      case GizmoMode.translate:
        return _moveGizmo;
      case GizmoMode.rotate:
        return _rotateGizmo;
      case GizmoMode.scale:
        return _scaleGizmo;
    }
  }

  // Controle de estado
  String? _activeAxis; 
  bool get isDragging => _activeAxis != null;
  
  final three.Raycaster _raycaster = three.Raycaster();
  final three.Vector2 _mouse = three.Vector2(0, 0);
  
  double _lastMouseX = 0;
  double _lastMouseY = 0;

  GizmoController(this.threeJs);

  /// Carrega todos os 3 gizmos
  Future<void> loadAllGizmos() async {
    final gizmos = await GizmoLoader.loadGizmos();
    _moveGizmo = gizmos['move'];
    _rotateGizmo = gizmos['rotate'];
    _scaleGizmo = gizmos['scale'];
    
    if (_moveGizmo != null) threeJs.scene.add(_moveGizmo!);
    if (_rotateGizmo != null) threeJs.scene.add(_rotateGizmo!);
    if (_scaleGizmo != null) threeJs.scene.add(_scaleGizmo!);
  }

  void update() {
    final selected = SelectionStore.instance.selected;
    
    _moveGizmo?.visible = false;
    _rotateGizmo?.visible = false;
    _scaleGizmo?.visible = false;

    if (selected == null || _activeGizmo == null) return;

    final gizmo = _activeGizmo!;
    gizmo.visible = true;

    gizmo.position.setValues(
      selected.transform.position.x,
      selected.transform.position.y,
      selected.transform.position.z,
    );
    
    gizmo.rotation.set(0, 0, 0);

    final distance = threeJs.camera.position.distanceTo(gizmo.position);
    final scale = distance * 0.001;
    gizmo.scale.setValues(scale, scale, scale);
  }

  bool onPointerDown(PointerDownEvent event, BuildContext context, Size size) {
    final gizmo = _activeGizmo;
    if (gizmo == null || !gizmo.visible) return false;

    _updateMouseCoordinates(event.localPosition, size);
    _raycaster.setFromCamera(_mouse, threeJs.camera);

    final intersects = _raycaster.intersectObject(gizmo, true);

    if (intersects.isNotEmpty) {
      final object = intersects.first.object;
      String? axis;
      if (object?.userData['axis'] != null) {
        axis = object?.userData['axis'] as String?;
      } 
      else if ((object?.name ?? '').contains('X')) axis = 'X';
      else if ((object?.name ?? '').contains('Y')) axis = 'Y';
      else if ((object?.name ?? '').contains('Z')) axis = 'Z';

      if (axis != null) {
        _activeAxis = axis;
        _lastMouseX = event.localPosition.dx;
        _lastMouseY = event.localPosition.dy;
        return true; // Consumiu o evento
      }
    }
    return false;
  }

  void onPointerMove(PointerMoveEvent event) {
     if (_activeAxis == null || SelectionStore.instance.selected == null) return;

     final dx = event.position.dx - _lastMouseX;
     final dy = event.position.dy - _lastMouseY;
     _lastMouseX = event.position.dx;
     _lastMouseY = event.position.dy;

     final mode = ToolStore.instance.activeMode;
     
     // 1. Calcular Delta
     final delta = GizmoTransformLogic.calculateDelta(mode, _activeAxis!, dx, dy);

     // 2. Aplicar Transformação (Imutável)
     final updatedObject = GizmoTransformLogic.applyTransform(
       original: SelectionStore.instance.selected!,
       mode: mode,
       axis: _activeAxis!,
       delta: delta,
     );

     // 3. Atualizar Stores
     ProjectStore.instance.updateGameObject(updatedObject);
     SelectionStore.instance.select(updatedObject);
     
     // 4. Atualizar visual do Gizmo
     update();
  }

  void onPointerUp() {
    _activeAxis = null;
  }

  void _updateMouseCoordinates(Offset offset, Size size) {
    if (size.width == 0 || size.height == 0) return;
    _mouse.x = (offset.dx / size.width) * 2 - 1;
    _mouse.y = -(offset.dy / size.height) * 2 + 1;
  }
}
