import 'package:flutter/foundation.dart';

enum GizmoMode { translate, rotate, scale }
enum TransformSpace { global, local }

class ToolStore extends ChangeNotifier {
  ToolStore._private();
  static final ToolStore instance = ToolStore._private();

  GizmoMode _activeMode = GizmoMode.translate;
  GizmoMode get activeMode => _activeMode;

  TransformSpace _transformSpace = TransformSpace.global;
  TransformSpace get transformSpace => _transformSpace;

  void setMode(GizmoMode mode) {
    if (_activeMode != mode) {
      _activeMode = mode;
      notifyListeners();
    }
  }

  void setTransformSpace(TransformSpace space) {
    if (_transformSpace != space) {
      _transformSpace = space;
      notifyListeners();
    }
  }

  void toggleTransformSpace() {
    setTransformSpace(_transformSpace == TransformSpace.global
        ? TransformSpace.local
        : TransformSpace.global);
  }
}
