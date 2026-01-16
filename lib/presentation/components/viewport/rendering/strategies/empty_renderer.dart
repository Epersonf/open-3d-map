import 'package:three_js/three_js.dart' as three;
import '../../../../../domain/scene/game_object.dart';
import '../scene_component_renderer.dart';

class EmptyRenderer implements SceneComponentRenderer {
  @override
  Future<three.Object3D> render(GameObject gameObject) async {
    final group = three.Group();
    final material = three.MeshBasicMaterial();
    material.color = three.Color.fromHex32(0x444444);
    material.wireframe = true;
    final helper = three.Mesh(
      three.BoxGeometry(0.5, 0.5, 0.5),
      material,
    );
    group.add(helper);
    return group;
  }
}
