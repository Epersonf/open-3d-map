import 'package:open_3d_mapper/domain/scene/game_object.dart';

import '../../../../../stores/tool_store.dart';
import '../gizmo_enums.dart';

abstract class TransformStrategy {
  double calculateDelta(GizmoAxis axis, double dx, double dy);
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space);
}
