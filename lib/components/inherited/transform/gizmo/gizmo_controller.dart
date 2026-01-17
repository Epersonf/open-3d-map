import 'package:flutter/material.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../../stores/tool_store.dart';
import 'package:open_3d_mapper/core/input/input_manager.dart';
import 'gizmo_loader.dart';
import 'gizmo_enums.dart';
import 'strategies/transform_strategy.dart';
import 'strategies/translate_strategy.dart';
import 'strategies/rotate_strategy.dart';
import 'strategies/scale_strategy.dart';

class GizmoController {
  // Singleton
  static final GizmoController instance = GizmoController._();
  GizmoController._() {
    // Se registra para receber inputs globais assim que nasce
    InputManager.instance.registerPriorityHandler(
      onDown: _onPointerDown,
      onMove: _onPointerMove,
      onUp: _onPointerUp,
    );
    ToolStore.instance.addListener(_updateVisuals);
  }

  three.Scene? _scene;
  three.Camera? _camera;
  GizmoAssets? _gizmoAssets;

  // Referência ao objeto 3D real da cena para cálculos de mundo
  three.Object3D? _currentObject3D;

  // Flag para evitar recarregar assets múltiplas vezes
  bool _initialized = false;

  final Map<GizmoMode, TransformStrategy> _strategies = {
    GizmoMode.translate: TranslateStrategy(),
    GizmoMode.rotate: RotateStrategy(),
    GizmoMode.scale: ScaleStrategy(),
  };

  GizmoAxis? _activeAxis;
  bool get isDragging => _activeAxis != null;

  double _lastMouseX = 0;
  double _lastMouseY = 0;

  final three.Raycaster _raycaster = three.Raycaster();
  final three.Vector2 _mouse = three.Vector2(0, 0);

  /// Chamado pelo TransformComponent.onStart
  void setup(three.Scene scene, three.Camera camera) {
    _scene = scene;
    _camera = camera;

    if (!_initialized) {
      _loadAllGizmos();
      _initialized = true;
    }
  }

  Future<void> _loadAllGizmos() async {
    _gizmoAssets = await GizmoLoader.loadGizmos();
    // Adiciona na cena se ela já estiver disponível
    if (_scene != null && _gizmoAssets != null) {
      if (_gizmoAssets!.move != null) _scene!.add(_gizmoAssets!.move!);
      if (_gizmoAssets!.rotate != null) _scene!.add(_gizmoAssets!.rotate!);
      if (_gizmoAssets!.scale != null) _scene!.add(_gizmoAssets!.scale!);
    }
  }

  // [FIX] Agora aceita o Object3D opcionalmente
  /// Chamado a cada frame ou quando a seleção muda (via TransformComponent)
  void update([three.Object3D? currentObject]) {
    if (currentObject != null) {
      _currentObject3D = currentObject;
    }
    _updateVisuals();
  }

  void _updateVisuals() {
    if (_scene == null || _camera == null) return;

    final selected = SelectionStore.instance.selected;
    if (selected == null) {
      _hideAll();
      return;
    }

    var transform = selected.getComponent<TransformComponent>();
    if (transform == null) {
      _hideAll();
      return;
    }

    _hideAll();
    if (_activeGizmoModel == null) return;

    final gizmo = _activeGizmoModel!;
    gizmo.visible = true;

    // [FIX] USAR WORLD POSITION
    // Em vez de usar transform.position (Local), pegamos a posição do mundo do Object3D
    if (_currentObject3D != null) {
      final worldPos = three.Vector3();
      _currentObject3D!.getWorldPosition(worldPos);
      gizmo.position.setValues(worldPos.x, worldPos.y, worldPos.z);

      // [FIX] Rotação do Gizmo
      final space = ToolStore.instance.transformSpace;
      if (space == TransformSpace.local) {
        // Se for Local, o gizmo deve acompanhar a rotação de mundo do objeto
        final worldQuat = three.Quaternion();
        _currentObject3D!.getWorldQuaternion(worldQuat);

        gizmo.quaternion.x = worldQuat.x;
        gizmo.quaternion.y = worldQuat.y;
        gizmo.quaternion.z = worldQuat.z;
        gizmo.quaternion.w = worldQuat.w;
      } else {
        // Global: sempre alinhado com o mundo (0,0,0)
        gizmo.rotation.set(0, 0, 0);
      }
    } else {
      // Fallback para comportamento antigo se algo der errado
      gizmo.position.setValues(
          transform.position.x, transform.position.y, transform.position.z);
    }

    final distance = _camera!.position.distanceTo(gizmo.position);
    final scale = distance * 0.001;
    gizmo.scale.setValues(scale, scale, scale);
  }

  void _hideAll() {
    _gizmoAssets?.move?.visible = false;
    _gizmoAssets?.rotate?.visible = false;
    _gizmoAssets?.scale?.visible = false;
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

  // --- Input Implementation (Chamado pelo InputManager) ---

  bool _onPointerDown(PointerDownEvent event, Size viewportSize) {
    if (_camera == null) return false;

    final gizmo = _activeGizmoModel;
    if (gizmo == null || !gizmo.visible) return false;

    _updateMouseCoordinates(event.localPosition, viewportSize);
    _raycaster.setFromCamera(_mouse, _camera!);

    final intersects = _raycaster.intersectObject(gizmo, true);

    if (intersects.isNotEmpty) {
      final object = intersects.first.object;
      if (object?.userData['gizmoAxis'] is GizmoAxis) {
        _activeAxis = object?.userData['gizmoAxis'] as GizmoAxis;
        _lastMouseX = event.localPosition.dx;
        _lastMouseY = event.localPosition.dy;
        return true; // Consumiu o evento
      }
    }
    return false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activeAxis == null || SelectionStore.instance.selected == null) return;

    final dx = event.position.dx - _lastMouseX;
    final dy = event.position.dy - _lastMouseY;
    _lastMouseX = event.position.dx;
    _lastMouseY = event.position.dy;

    final mode = ToolStore.instance.activeMode;
    final space = ToolStore.instance.transformSpace;
    final strategy = _strategies[mode];

    if (strategy != null) {
      final delta = strategy.calculateDelta(_activeAxis!, dx, dy);
      final updatedObject = strategy.apply(
        SelectionStore.instance.selected!,
        _activeAxis!,
        delta,
        space,
        _currentObject3D, // [FIX] Passamos o objeto 3D para cálculo de matrizes
      );

      ProjectStore.instance.updateGameObject(updatedObject);
      SelectionStore.instance.select(updatedObject);
      update();
    }
  }

  void _onPointerUp() {
    _activeAxis = null;
  }

  void _updateMouseCoordinates(Offset offset, Size size) {
    if (size.width == 0 || size.height == 0) return;
    _mouse.x = (offset.dx / size.width) * 2 - 1;
    _mouse.y = -(offset.dy / size.height) * 2 + 1;
  }
}
