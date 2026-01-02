import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter_scene/scene.dart';

class FlyCameraController {
  FlyCameraController(this.camera) {
    final dir = (camera.target - camera.position).normalized();
    yaw = math.atan2(dir.x, dir.z);
    pitch = math.asin(dir.y.clamp(-1.0, 1.0));
  }

  final PerspectiveCamera camera;

  final Set<LogicalKeyboardKey> _pressed = {};

  bool _rotating = false;
  Offset? _lastPointerPos;

  double moveSpeed = 0.05;
  double mouseSensitivity = 0.005;

  double yaw = 0;
  double pitch = 0;

  void onPointerDown(PointerDownEvent e) {
    if (e.buttons & kSecondaryMouseButton != 0) {
      _rotating = true;
      _lastPointerPos = e.position;
    }
  }

  void onPointerUp(PointerUpEvent e) {
    _rotating = false;
    _lastPointerPos = null;
  }

  void onPointerMove(PointerMoveEvent e) {
    if (!_rotating || _lastPointerPos == null) return;

    final dx = e.position.dx - _lastPointerPos!.dx;
    final dy = e.position.dy - _lastPointerPos!.dy;
    _lastPointerPos = e.position;

    // inverter apenas yaw (esquerda/direita)
    yaw += dx * mouseSensitivity;

    // pitch estava certo, mantém
    pitch -= dy * mouseSensitivity;
    const maxPitch = math.pi / 2 - 0.01;
    pitch = pitch.clamp(-maxPitch, maxPitch);

    _updateCameraTargetFromAngles();
  }

  void onKeyDown(LogicalKeyboardKey key) {
    _pressed.add(key);
  }

  void onKeyUp(LogicalKeyboardKey key) {
    _pressed.remove(key);
  }

  void update() {
    if (_pressed.isEmpty) return;

    final forward = _getForward();

    // CORRETO AGORA
    final right = forward.cross(camera.up).normalized();

    Vector3 delta = Vector3.zero();

    if (_pressed.contains(LogicalKeyboardKey.keyW)) {
      delta += forward * moveSpeed;
    }
    if (_pressed.contains(LogicalKeyboardKey.keyS)) {
      delta -= forward * moveSpeed;
    }

    // A = esquerda
    if (_pressed.contains(LogicalKeyboardKey.keyA)) {
      delta += right * moveSpeed;
    }

    // D = direita
    if (_pressed.contains(LogicalKeyboardKey.keyD)) {
      delta -= right * moveSpeed;
    }

    if (delta.length2 != 0) {
      camera.position += delta;
      camera.target += delta;
    }
  }

  Vector3 _getForward() {
    final cp = math.cos(pitch);
    return Vector3(
      math.sin(yaw) * cp,
      math.sin(pitch),
      math.cos(yaw) * cp,
    ).normalized();
  }

  void _updateCameraTargetFromAngles() {
    final forward = _getForward();
    camera.target = camera.position + forward;
  }
}
