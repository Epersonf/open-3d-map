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

  // --- Grid / Magnet Settings ---
  bool _snapEnabled = false;
  bool get snapEnabled => _snapEnabled;

  double _snapIncrement = 1.0;
  double get snapIncrement => _snapIncrement;

  // true = Snap to World Grid (0, 1, 2)
  // false = Snap Relative to Object (Current Pos + Increment)
  bool _snapToGrid = true;
  bool get snapToGrid => _snapToGrid;

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

  // --- Grid Actions ---

  void setSnapEnabled(bool value) {
    if (_snapEnabled != value) {
      _snapEnabled = value;
      notifyListeners();
    }
  }

  void setSnapIncrement(double value) {
    if (_snapIncrement != value) {
      _snapIncrement = value;
      notifyListeners();
    }
  }

  void setSnapToGrid(bool value) {
    if (_snapToGrid != value) {
      _snapToGrid = value;
      notifyListeners();
    }
  }
}
