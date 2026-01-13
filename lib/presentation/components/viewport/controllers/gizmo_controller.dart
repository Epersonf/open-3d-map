import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../../../../core/utils/model_import.dart';
import '../../../../domain/scene/game_object.dart';
import '../../../../domain/scene/transform.dart' as domain;

class GizmoController {
  final three.ThreeJS threeJs;
  three.Object3D? _gizmoModel;
  
  // Controle de estado
  String? _activeAxis; // 'X', 'Y', 'Z' ou null
  bool get isDragging => _activeAxis != null;
  
  // Raycasting exclusivo para o Gizmo
  final three.Raycaster _raycaster = three.Raycaster();
  final three.Vector2 _mouse = three.Vector2(0, 0);
  
  // Para cálculo de movimento
  double _lastMouseX = 0;
  double _lastMouseY = 0;

  GizmoController(this.threeJs) {
    // nada a fazer por enquanto
  }

  Future<void> loadGizmo(String path) async {
    final model = await ModelImport.loadModel(path);
    if (model != null) {
      // clone para evitar compartilhamento com possíveis caches
      _gizmoModel = model.clone();
      _gizmoModel!.visible = false;

      _gizmoModel!.traverse((child) {
        if (child is three.Mesh) {
          child.renderOrder = 999;
          if (child.material != null) {
            child.material!.depthTest = false;
            child.material!.transparent = true;
          }

          final n = (child.name).toLowerCase();
          if (n.contains('x')) child.userData['axis'] = 'X';
          if (n.contains('y')) child.userData['axis'] = 'Y';
          if (n.contains('z')) child.userData['axis'] = 'Z';
        }
      });

      threeJs.scene.add(_gizmoModel!);
    }
  }

  /// Load the gizmo model from the Flutter asset bundle by copying it to
  /// a temporary file and letting the existing ModelImport read it.
  Future<void> loadGizmoFromAssets() async {
    try {
      const assetPath = 'assets/3d/MoveArrows.fbx';
      final temp = await _assetToTempFile(assetPath);
      final model = await ModelImport.loadModel(temp.path);
      if (model != null) {
        _gizmoModel = model.clone();
        _setupGizmoVisuals();
        threeJs.scene.add(_gizmoModel!);
      } else {
        print('Gizmo model loaded from assets is null');
      }
    } catch (e) {
      print('Error loading gizmo from assets: $e');
    }
  }

  Future<File> _assetToTempFile(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final tmpDir = Directory.systemTemp;
    final file = File('${tmpDir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _setupGizmoVisuals() {
    if (_gizmoModel == null) return;

    // Esconde por padrão até ter seleção
    _gizmoModel!.visible = false;

    _gizmoModel!.traverse((child) {
      if (child is three.Mesh) {
        // Garante que renderize na frente de tudo
        child.renderOrder = 999;

        final n = (child.name).toLowerCase();

        String? axis;
        three.Color color = three.Color.fromHex32(0xFFFFFF);

        // Correção de mapeamento dos eixos baseada no export FBX
        // Arrow1 = Y (Verde)
        if (n.contains('arrow1') || n.contains('y')) {
          axis = 'Y';
          color = three.Color.fromHex32(0x00FF00);
        }
        // Arrow2 = X (Vermelho) -- invertido em relação à versão anterior
        else if (n.contains('arrow2') || n.contains('x')) {
          axis = 'X';
          color = three.Color.fromHex32(0xFF0000);
        }
        // Arrow3 = Z (Azul) -- invertido em relação à versão anterior
        else if (n.contains('arrow3') || n.contains('z')) {
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
    if (selected == null || _gizmoModel == null) {
      _gizmoModel?.visible = false;
      return;
    }

    _gizmoModel!.visible = true;

    _gizmoModel!.position.setValues(
      selected.transform.position.x,
      selected.transform.position.y,
      selected.transform.position.z,
    );

    final distance = threeJs.camera.position.distanceTo(_gizmoModel!.position);
    // Ajuste: reduzir o fator para que o gizmo fique menor na tela
    // Valores sugeridos: 0.04 (padrão), 0.03, 0.02 — ajustar conforme necessário
    final scale = distance * 0.001;
    _gizmoModel!.scale.setValues(scale, scale, scale);
  }

  bool onPointerDown(PointerDownEvent event, BuildContext context, Size size) {
    if (_gizmoModel == null || !_gizmoModel!.visible) return false;

    // Use localPosition to compute NDC consistently
    _updateMouseCoordinates(event.localPosition, size);

    _raycaster.setFromCamera(_mouse, threeJs.camera);

    final intersects = _raycaster.intersectObject(_gizmoModel!, true);

    if (intersects.isNotEmpty) {
      final object = intersects.first.object;
      String? axis;
      if (object?.userData['axis'] != null) {
        axis = object?.userData['axis'] as String?;
      } else if ((object?.name ?? '').contains('X')) axis = 'X';
      else if ((object?.name ?? '').contains('Y')) axis = 'Y';
      else if ((object?.name ?? '').contains('Z')) axis = 'Z';

      if (axis != null) {
        _activeAxis = axis;
        // Initialize last mouse to avoid jump when starting drag
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

    const speed = 0.05;
    double delta = 0;

    if (_activeAxis == 'X') delta = dx * speed;
    if (_activeAxis == 'Y') delta = -dy * speed;
    if (_activeAxis == 'Z') delta = -dx * speed;

    _applyMove(delta);
  }

  void onPointerUp() {
    _activeAxis = null;
  }

  void _applyMove(double delta) {
    final selected = SelectionStore.instance.selected!;

    double newX = selected.transform.position.x;
    double newY = selected.transform.position.y;
    double newZ = selected.transform.position.z;

    if (_activeAxis == 'X') newX += delta;
    if (_activeAxis == 'Y') newY += delta;
    if (_activeAxis == 'Z') newZ += delta;

    final updated = GameObject(
      id: selected.id,
      name: selected.name,
      parentId: selected.parentId,
      assetId: selected.assetId,
      transform: domain.Transform(
        position: domain.Vec3(x: newX, y: newY, z: newZ),
        rotation: selected.transform.rotation,
        scale: selected.transform.scale,
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
