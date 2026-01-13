import 'package:flutter/foundation.dart';

enum GizmoMode { translate, rotate, scale }

class ToolStore extends ChangeNotifier {
  ToolStore._private();
  static final ToolStore instance = ToolStore._private();

  GizmoMode _activeMode = GizmoMode.translate;
  GizmoMode get activeMode => _activeMode;

  void setMode(GizmoMode mode) {
    if (_activeMode != mode) {
      _activeMode = mode;
      notifyListeners();
    }
  }
}
