import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:three_js/three_js.dart' as three;
import '../../../../core/utils/model_import.dart';
import 'gizmo_enums.dart';

/// Classe simples para segurar os assets carregados de forma tipada
class GizmoAssets {
  final three.Object3D? move;
  final three.Object3D? rotate;
  final three.Object3D? scale;

  GizmoAssets({this.move, this.rotate, this.scale});
}

class GizmoLoader {
  static Future<GizmoAssets> loadGizmos() async {
    final move = await _loadSingleGizmo('assets/3d/MoveArrows.fbx');
    final rotate = await _loadSingleGizmo('assets/3d/RotateArrows.fbx');
    final scale = await _loadSingleGizmo('assets/3d/ScaleArrows.fbx');

    return GizmoAssets(move: move, rotate: rotate, scale: scale);
  }

  static Future<three.Object3D?> _loadSingleGizmo(String assetPath) async {
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

  static Future<File> _assetToTempFile(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final tmpDir = Directory.systemTemp;
    final file = File('${tmpDir.path}/${assetPath.split('/').last.replaceAll('.fbx', '')}_${DateTime.now().millisecondsSinceEpoch}.fbx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static void _setupGizmoVisuals(three.Object3D model) {
    model.traverse((child) {
      if (child is three.Mesh) {
        child.renderOrder = 999;
        
        final n = (child.name ?? '').toLowerCase();
        GizmoAxis? axis;
        three.Color color = three.Color.fromHex32(0xFFFFFF);

        if (n.contains('arrow1') || n.contains('y') || n.contains('green')) {
          axis = GizmoAxis.y;
          color = three.Color.fromHex32(0x00FF00);
        } else if (n.contains('arrow2') || n.contains('x') || n.contains('red')) {
          axis = GizmoAxis.x;
          color = three.Color.fromHex32(0xFF0000);
        } else if (n.contains('arrow3') || n.contains('z') || n.contains('blue')) {
          axis = GizmoAxis.z;
          color = three.Color.fromHex32(0x0000FF);
        }

        if (axis != null) {
          child.userData['gizmoAxis'] = axis;
          
          final mat = three.MeshBasicMaterial();
          mat.color = color;
          child.material = mat;
          child.material!.depthTest = false;
          child.material!.transparent = true;
        }
      }
    });
  }
}
