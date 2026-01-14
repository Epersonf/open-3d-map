import 'package:flutter/foundation.dart';
import '../domain/scene/game_object.dart';

class CameraStore extends ChangeNotifier {
  CameraStore._private();
  static final CameraStore instance = CameraStore._private();

  GameObject? _focusTarget;
  GameObject? get focusTarget => _focusTarget;

  /// Solicita que a câmera foque neste objeto
  void requestFocus(GameObject target) {
    _focusTarget = target;
    notifyListeners();
  }

  /// Limpa o pedido após ser consumido pelo Viewport
  void consumeRequest() {
    _focusTarget = null;
  }
}
