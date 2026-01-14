import '../../../../../domain/scene/game_object.dart';
import '../gizmo_enums.dart';

/// Define o contrato para qualquer lógica de transformação (Move, Rotate, Scale)
abstract class TransformStrategy {
  /// Calcula quanto o valor deve mudar com base no movimento do mouse
  double calculateDelta(GizmoAxis axis, double dx, double dy);

  /// Aplica a transformação e retorna um novo GameObject
  GameObject apply(GameObject original, GizmoAxis axis, double delta);
}
