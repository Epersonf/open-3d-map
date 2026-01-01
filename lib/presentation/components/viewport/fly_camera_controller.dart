import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';

class FlyCameraController {
  FlyCameraController(this.camera);

  final PerspectiveCamera camera;

  final Set<LogicalKeyboardKey> _pressed = {};
  bool _active = false; // botão direito pressionado?

  double moveSpeed = 0.05;

  void onPointerDown(int buttons) {
    if (buttons == kSecondaryMouseButton) {
      _active = true;
    }
  }

  void onPointerUp(int buttons) {
    if (buttons == kSecondaryMouseButton) {
      _active = false;
    }
  }

  void onKeyDown(LogicalKeyboardKey key) {
    _pressed.add(key);
  }

  void onKeyUp(LogicalKeyboardKey key) {
    _pressed.remove(key);
  }

  void update() {
    if (!_active) return;
    if (_pressed.isEmpty) return;

    final forward = (camera.target - camera.position).normalized();
    final right = forward.cross(camera.up).normalized();

    if (_pressed.contains(LogicalKeyboardKey.keyW)) {
      camera.position += forward * moveSpeed;
      camera.target += forward * moveSpeed;
    }
    if (_pressed.contains(LogicalKeyboardKey.keyS)) {
      camera.position -= forward * moveSpeed;
      camera.target -= forward * moveSpeed;
    }
    if (_pressed.contains(LogicalKeyboardKey.keyA)) {
      camera.position -= right * moveSpeed;
      camera.target -= right * moveSpeed;
    }
    if (_pressed.contains(LogicalKeyboardKey.keyD)) {
      camera.position += right * moveSpeed;
      camera.target += right * moveSpeed;
    }
  }
}
