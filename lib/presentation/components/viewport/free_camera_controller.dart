import 'dart:math' as Math;

import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;

class FreeCameraController {
  final three.ThreeJS threeJs;

  late three.Camera camera;

  bool rightMouseDown = false;

  final Set<LogicalKeyboardKey> keys = {};

  double baseSpeed = 6.0;
  double runMultiplier = 2.5;
  double lookSpeed = 2.5;

  FreeCameraController(this.threeJs) {
    camera = threeJs.camera;

    threeJs.addAnimationEvent(_update);
  }

  void _update(double dt) {
    if (!rightMouseDown) return;

    double speed = baseSpeed * dt;

    if (keys.contains(LogicalKeyboardKey.shiftLeft)) {
      speed *= runMultiplier;
    }

    final forward = three.Vector3(
      -Math.sin(camera.rotation.y),
      0,
      -Math.cos(camera.rotation.y),
    );

    final right = three.Vector3(
      Math.cos(camera.rotation.y),
      0,
      -Math.sin(camera.rotation.y),
    );

    if (keys.contains(LogicalKeyboardKey.keyW)) {
      camera.position.addScaled(forward, speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyS)) {
      camera.position.addScaled(forward, -speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyA)) {
      camera.position.addScaled(right, -speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyD)) {
      camera.position.addScaled(right, speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyE)) {
      camera.position.y += speed;
    }
    if (keys.contains(LogicalKeyboardKey.keyQ)) {
      camera.position.y -= speed;
    }
  }
}
