import 'package:three_js/three_js.dart' as three;
import '../../../../domain/scene/game_object.dart';

/// Define o contrato para converter um componente visual em um Objeto 3D
abstract class SceneComponentRenderer {
  Future<three.Object3D> render(GameObject gameObject);
}
