import '../../../../../domain/scene/game_object.dart';
import '../../../../../stores/tool_store.dart';
import '../gizmo_enums.dart';

/// Define o contrato para qualquer lógica de transformação (Move, Rotate, Scale)
abstract class TransformStrategy {
  /// Calcula quanto o valor deve mudar com base no movimento do mouse
  double calculateDelta(GizmoAxis axis, double dx, double dy);

  /// Aplica a transformação e retorna um novo GameObject
  /// [space] determina se a operação é em espaço global ou local
  GameObject apply(GameObject original, GizmoAxis axis, double delta, TransformSpace space);
}
