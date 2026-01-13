import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../../stores/tool_store.dart';
import '../../../../core/utils/model_import.dart';
import '../../../../domain/scene/game_object.dart';
import '../../../../domain/scene/transform.dart' as domain;

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
    _moveGizmo = await _loadSingleGizmo('assets/3d/MoveArrows.fbx');
    _rotateGizmo = await _loadSingleGizmo('assets/3d/RotateArrows.fbx');
    _scaleGizmo = await _loadSingleGizmo('assets/3d/ScaleArrows.fbx');
    
    if (_moveGizmo != null) threeJs.scene.add(_moveGizmo!);
    if (_rotateGizmo != null) threeJs.scene.add(_rotateGizmo!);
    if (_scaleGizmo != null) threeJs.scene.add(_scaleGizmo!);
  }

  Future<three.Object3D?> _loadSingleGizmo(String assetPath) async {
    try {
      final temp = await _assetToTempFile(assetPath);
      final model = await ModelImport.loadModel(temp.path);
      if (model != null) {
        final clone = model.clone();
        _setupGizmoVisuals(clone);
        clone.visible = false;
        return clone;
      }
    } catch (e) {
      print('Erro ao carregar gizmo $assetPath: $e');
    }
    return null;
  }

  Future<File> _assetToTempFile(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final tmpDir = Directory.systemTemp;
    final file = File('${tmpDir.path}/${assetPath.split('/').last.replaceAll('.fbx', '')}_${DateTime.now().millisecondsSinceEpoch}.fbx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _setupGizmoVisuals(three.Object3D model) {
    model.traverse((child) {
      if (child is three.Mesh) {
        child.renderOrder = 999;
        
        final n = (child.name ?? '').toLowerCase();
        String? axis;
        three.Color color = three.Color.fromHex32(0xFFFFFF);

        if (n.contains('arrow1') || n.contains('y') || n.contains('green')) {
          axis = 'Y';
          color = three.Color.fromHex32(0x00FF00);
        } else if (n.contains('arrow2') || n.contains('x') || n.contains('red')) {
          axis = 'X';
          color = three.Color.fromHex32(0xFF0000);
        } else if (n.contains('arrow3') || n.contains('z') || n.contains('blue')) {
          axis = 'Z';
          color = three.Color.fromHex32(0x0000FF);
        }

        if (axis != null) {
          child.userData['axis'] = axis;
          final mat = three.MeshBasicMaterial();
          mat.color = color;
          child.material = mat;
          child.material!.depthTest = false;
          child.material!.transparent = true;
        }
      }
    });
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
     double delta = 0;

     // --- CORREÇÃO DA LÓGICA DE MOVIMENTO ---
     if (mode == GizmoMode.rotate) {
       // Sensibilidade da rotação (Graus por pixel)
       const rotateSpeed = 0.8; 
       
       // Eixo X (Vermelho): Mover mouse para cima/baixo (dy) rotaciona em X
       if (_activeAxis == 'X') delta = dy * rotateSpeed;
       
       // Eixo Y (Verde): Mover mouse para lados (dx) rotaciona em Y
       if (_activeAxis == 'Y') delta = dx * rotateSpeed;
       
       // Eixo Z (Azul): Mover mouse para lados (dx) inclina em Z
       if (_activeAxis == 'Z') delta = -dx * rotateSpeed;
       
     } else {
       // Move e Scale mantêm a lógica direcional
       const speed = 0.05; 
       if (_activeAxis == 'X') delta = dx * speed;
       if (_activeAxis == 'Y') delta = -dy * speed;
       if (_activeAxis == 'Z') delta = -dx * speed;
     }

     _applyTransform(delta);
  }

  void onPointerUp() {
    _activeAxis = null;
  }

  void _applyTransform(double delta) {
    final selected = SelectionStore.instance.selected!;
    final mode = ToolStore.instance.activeMode;

    double px = selected.transform.position.x;
    double py = selected.transform.position.y;
    double pz = selected.transform.position.z;

    double sx = selected.transform.scale.x;
    double sy = selected.transform.scale.y;
    double sz = selected.transform.scale.z;
    
    double rx = selected.transform.rotation.x;
    double ry = selected.transform.rotation.y;
    double rz = selected.transform.rotation.z;

    if (mode == GizmoMode.translate) {
      if (_activeAxis == 'X') px += delta;
      if (_activeAxis == 'Y') py += delta;
      if (_activeAxis == 'Z') pz += delta;
    } 
    else if (mode == GizmoMode.scale) {
      if (_activeAxis == 'X') sx += delta;
      if (_activeAxis == 'Y') sy += delta;
      if (_activeAxis == 'Z') sz += delta;
      if (sx < 0.01) sx = 0.01;
      if (sy < 0.01) sy = 0.01;
      if (sz < 0.01) sz = 0.01;
    }
    // --- LÓGICA DE ROTAÇÃO ADICIONADA ---
    else if (mode == GizmoMode.rotate) {
      if (_activeAxis == 'X') rx += delta;
      if (_activeAxis == 'Y') ry += delta;
      if (_activeAxis == 'Z') rz += delta;
    }

    final updated = GameObject(
      id: selected.id,
      name: selected.name,
      parentId: selected.parentId,
      assetId: selected.assetId,
      transform: domain.Transform(
        position: domain.Vec3(x: px, y: py, z: pz),
        rotation: domain.Vec3(x: rx, y: ry, z: rz),
        scale: domain.Vec3(x: sx, y: sy, z: sz),
      ),
      tags: selected.tags,
      children: selected.children,
    );

    ProjectStore.instance.updateGameObject(updated);
    SelectionStore.instance.select(updated);
    update();
  }

  void _updateMouseCoordinates(Offset offset, Size size) {
    if (size.width == 0 || size.height == 0) return;
    _mouse.x = (offset.dx / size.width) * 2 - 1;
    _mouse.y = -(offset.dy / size.height) * 2 + 1;
  }
}
