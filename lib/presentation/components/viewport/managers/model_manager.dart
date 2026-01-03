import 'dart:async';
import 'package:three_js/three_js.dart' as three;
import 'package:path/path.dart' as p;
import '../../../../core/utils/model_import.dart';

class ModelManager {
  final Map<String, three.Object3D> _loadedModels = {};

  Future<three.Object3D?> loadModel(String assetId, String projectPath, String assetPath) async {
    if (_loadedModels.containsKey(assetId)) {
      return _loadedModels[assetId];
    }

    final absolutePath = p.join(projectPath, assetPath);
    final model = await ModelImport.loadModel(absolutePath);
    
    if (model != null) {
      _loadedModels[assetId] = model;
      return model;
    } else {
      final fallback = _createFallbackObject(assetId);
      _loadedModels[assetId] = fallback;
      return fallback;
    }
  }

  three.Object3D _createFallbackObject(String assetId) {
    final geometry = three.BoxGeometry(1, 1, 1);
    final material = three.MeshStandardMaterial();
    material.color = three.Color.fromHex32(0xff0000);
    material.wireframe = true;

    final cube = three.Mesh(geometry, material);
    cube.name = 'Fallback: $assetId';
    return cube;
  }

  three.Object3D? getModel(String assetId) => _loadedModels[assetId];

  void clear() {
    _loadedModels.clear();
  }
}
