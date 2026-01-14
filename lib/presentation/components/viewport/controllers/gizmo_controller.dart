import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../../stores/tool_store.dart';
import '../gizmo/gizmo_loader.dart';
import '../gizmo/gizmo_enums.dart';
import '../gizmo/strategies/transform_strategy.dart';
import '../gizmo/strategies/translate_strategy.dart';
import '../gizmo/strategies/rotate_strategy.dart';
import '../gizmo/strategies/scale_strategy.dart';

class GizmoController {
  final three.ThreeJS threeJs;
  
  // Assets
  GizmoAssets? _gizmoAssets;
  
  // Mapa de estratégias: Conecta o Enum do Store com a Lógica correspondente
  final Map<GizmoMode, TransformStrategy> _strategies = {
    GizmoMode.translate: TranslateStrategy(),
    GizmoMode.rotate: RotateStrategy(),
    GizmoMode.scale: ScaleStrategy(),
  };
  
  // Estado
  GizmoAxis? _activeAxis; 
  bool get isDragging => _activeAxis != null;
  double _lastMouseX = 0;
  double _lastMouseY = 0;

  final three.Raycaster _raycaster = three.Raycaster();
  final three.Vector2 _mouse = three.Vector2(0, 0);

  GizmoController(this.threeJs);

  /// Carrega todos os 3 gizmos
  Future<void> loadAllGizmos() async {
    _gizmoAssets = await GizmoLoader.loadGizmos();
    
    if (_gizmoAssets!.move != null) threeJs.scene.add(_gizmoAssets!.move!);
    if (_gizmoAssets!.rotate != null) threeJs.scene.add(_gizmoAssets!.rotate!);
    if (_gizmoAssets!.scale != null) threeJs.scene.add(_gizmoAssets!.scale!);
  }

  void update() {
    final selected = SelectionStore.instance.selected;
    
    _gizmoAssets?.move?.visible = false;
    _gizmoAssets?.rotate?.visible = false;
    _gizmoAssets?.scale?.visible = false;

    if (selected == null || _activeGizmoModel == null) return;

    final gizmo = _activeGizmoModel!;
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

  three.Object3D? get _activeGizmoModel {
    if (_gizmoAssets == null) return null;
    switch (ToolStore.instance.activeMode) {
      case GizmoMode.translate:
        return _gizmoAssets!.move;
      case GizmoMode.rotate:
        return _gizmoAssets!.rotate;
      case GizmoMode.scale:
        return _gizmoAssets!.scale;
    }
  }

  bool onPointerDown(PointerDownEvent event, BuildContext context, Size size) {
    final gizmo = _activeGizmoModel;
    if (gizmo == null || !gizmo.visible) return false;

    _updateMouseCoordinates(event.localPosition, size);
    _raycaster.setFromCamera(_mouse, threeJs.camera);

    final intersects = _raycaster.intersectObject(gizmo, true);

    if (intersects.isNotEmpty) {
      final object = intersects.first.object;
      
      // Recuperar o Enum do userData (tipado)
      if (object?.userData['gizmoAxis'] is GizmoAxis) {
        _activeAxis = object?.userData['gizmoAxis'] as GizmoAxis;
        _lastMouseX = event.localPosition.dx;
        _lastMouseY = event.localPosition.dy;
        return true; 
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
     final strategy = _strategies[mode];

     if (strategy != null) {
       // 1. Calcular Delta via Strategy
       final delta = strategy.calculateDelta(_activeAxis!, dx, dy);

       // 2. Aplicar Transformação via Strategy
       final updatedObject = strategy.apply(
         SelectionStore.instance.selected!,
         _activeAxis!,
         delta,
       );

       // 3. Atualizar Stores
       ProjectStore.instance.updateGameObject(updatedObject);
       SelectionStore.instance.select(updatedObject);
       
       update();
     }
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
