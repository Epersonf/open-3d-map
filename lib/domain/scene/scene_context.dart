import 'package:three_js/three_js.dart' as three;
import 'package:open_3d_mapper/presentation/components/viewport/managers/model_manager.dart';
import 'package:open_3d_mapper/stores/project_store.dart';

/// O contexto passado para os componentes durante o ciclo de vida.
/// Permite que o componente interaja com a cena 3D.
class SceneContext {
  final three.Object3D parent; // O nó pai (o SceneObject wrapper) onde o componente deve se anexar
  final three.Scene scene; // A cena global (caso precise de acesso global)
  final ModelManager modelManager;
  final ProjectStore projectStore;

  SceneContext({
    required this.parent,
    required this.scene,
    required this.modelManager,
    required this.projectStore,
  });
}
