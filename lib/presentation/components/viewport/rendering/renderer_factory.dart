import 'package:open_3d_mapper/presentation/components/viewport/managers/model_manager.dart';

import '../../../../components/inherited/visual/visual_component.dart';
import 'scene_component_renderer.dart';
import 'strategies/icon_renderer.dart';
import 'strategies/mesh_renderer.dart';
import 'strategies/empty_renderer.dart';

class RendererFactory {
  final ModelManager modelManager;
  final String projectPath;

  RendererFactory({
    required this.modelManager,
    required this.projectPath,
  });

  SceneComponentRenderer getRenderer(VisualType type) {
    switch (type) {
      case VisualType.icon:
        return IconRenderer();
      case VisualType.mesh:
        return MeshRenderer(modelManager: modelManager, projectPath: projectPath);
      case VisualType.none:
      return EmptyRenderer();
    }
  }
}
