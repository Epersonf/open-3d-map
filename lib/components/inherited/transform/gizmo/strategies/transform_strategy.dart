import 'package:open_3d_mapper/domain/scene/game_object/game_object.dart';
import 'package:three_js/three_js.dart' as three;

import '../../../../../stores/tool_store.dart';
import '../gizmo_enums.dart';

abstract class TransformStrategy {
  double calculateDelta(GizmoAxis axis, double dx, double dy);

  // Adicionado parâmetro object3d para permitir cálculo envolvendo o pai/world
  GameObject apply(GameObject original, GizmoAxis axis, double delta,
      TransformSpace space, three.Object3D? object3d);
}
