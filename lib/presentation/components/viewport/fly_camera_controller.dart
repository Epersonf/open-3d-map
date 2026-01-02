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
  double sprintMoveSpeed = 0.15; // Nova velocidade para quando Shift está pressionado
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

    // Determina a velocidade baseada se Shift está pressionado
    final double currentMoveSpeed = _isSprinting() ? sprintMoveSpeed : moveSpeed;

    Vector3 delta = Vector3.zero();

    if (_pressed.contains(LogicalKeyboardKey.keyW)) {
      delta += forward * currentMoveSpeed;
    }
    if (_pressed.contains(LogicalKeyboardKey.keyS)) {
      delta -= forward * currentMoveSpeed;
    }

    // A = esquerda
    if (_pressed.contains(LogicalKeyboardKey.keyA)) {
      delta += right * currentMoveSpeed;
    }

    // D = direita
    if (_pressed.contains(LogicalKeyboardKey.keyD)) {
      delta -= right * currentMoveSpeed;
    }

    // Movimento vertical: E = cima, Q = baixo
    if (_pressed.contains(LogicalKeyboardKey.keyE)) {
      delta += camera.up * currentMoveSpeed;
    }
    if (_pressed.contains(LogicalKeyboardKey.keyQ)) {
      delta -= camera.up * currentMoveSpeed;
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

  // Verifica se Shift está pressionado (esquerdo ou direito)
  bool _isSprinting() {
    return _pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        _pressed.contains(LogicalKeyboardKey.shiftRight);
  }
}
