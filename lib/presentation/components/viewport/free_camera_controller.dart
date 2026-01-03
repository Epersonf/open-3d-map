import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:three_js/three_js.dart' as three;

class FreeCameraController {
  final three.ThreeJS threeJs;

  bool rightMouseDown = false;
  final Set<LogicalKeyboardKey> keys = {};

  double baseSpeed = 6.0;
  double runMultiplier = 2.5;
  double lookSpeed = 2.5;

  FreeCameraController(this.threeJs) {
    threeJs.addAnimationEvent(_update);
  }

  void onPointerDown(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.mouse &&
        e.buttons == kSecondaryMouseButton) {
      rightMouseDown = true;
    }
  }

  void onPointerUp(PointerUpEvent e) {
    if (e.kind == PointerDeviceKind.mouse) {
      rightMouseDown = false;
    }
  }

  void onPointerMove(PointerMoveEvent e) {
    if (!rightMouseDown) return;

    final cam = threeJs.camera;

    cam.rotation.y -= e.delta.dx * 0.0025 * lookSpeed;

    cam.rotation.x -= e.delta.dy * 0.0025 * lookSpeed;

    const double maxPitch = 1.45;
    if (cam.rotation.x > maxPitch) cam.rotation.x = maxPitch;
    if (cam.rotation.x < -maxPitch) cam.rotation.x = -maxPitch;

    cam.rotation.z = 0;
  }

  void onKey(KeyEvent e) {
    final key = e.logicalKey;

    if (e is KeyDownEvent) {
      keys.add(key);
    } else if (e is KeyUpEvent) {
      keys.remove(key);
    }
  }

  void _update(double dt) {
    if (!rightMouseDown) return;

    final cam = threeJs.camera;

    double speed = baseSpeed * dt;
    if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight)) {
      speed *= runMultiplier;
    }

    // direção real no espaço
    final forward = three.Vector3.zero();
    cam.getWorldDirection(forward);

    // remove componente vertical do right para não inclinar strafing
    final right = three.Vector3(0, 1, 0).cross(forward);
    right.normalize();

    if (keys.contains(LogicalKeyboardKey.keyW)) {
      cam.position.addScaled(forward, speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyS)) {
      cam.position.addScaled(forward, -speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyA)) {
      cam.position.addScaled(right, -speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyD)) {
      cam.position.addScaled(right, speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyE)) {
      cam.position.y += speed;
    }
    if (keys.contains(LogicalKeyboardKey.keyQ)) {
      cam.position.y -= speed;
    }
  }

  void dispose() {}
}
