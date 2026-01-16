import 'package:open_3d_mapper/components/inherited/visual/visual_component.dart';
import 'package:open_3d_mapper/presentation/components/viewport/managers/model_manager.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../../domain/scene/game_object.dart';
import '../scene_component_renderer.dart';

class MeshRenderer implements SceneComponentRenderer {
  final ModelManager modelManager;
  final String projectPath;

  MeshRenderer({required this.modelManager, required this.projectPath});

  @override
  Future<three.Object3D> render(GameObject gameObject) async {
    var visual = gameObject.getComponent<VisualComponent>();
    if (visual == null) {
      return three.Group();
    }
    final assetId = visual.assetId;
    if (assetId != null) {
      final model = await modelManager.loadModel(assetId, projectPath, '');
      if (model != null) return model.clone();
    }

    // Fallback visual
    final geometry = three.BoxGeometry(1, 1, 1);
    final material = three.MeshBasicMaterial();
    material.color = three.Color.fromHex32(0xFF0000);
    material.wireframe = true;
    return three.Mesh(geometry, material);
  }
}
