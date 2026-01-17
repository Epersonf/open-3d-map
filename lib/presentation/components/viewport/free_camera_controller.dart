import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:open_3d_mapper/core/input/input_manager.dart';

class FreeCameraController {
  final three.ThreeJS threeJs;

  bool rightMouseDown = false;

  // Configurações de velocidade
  double baseSpeed = 6.0;
  double runMultiplier = 2.5;
  double lookSpeed = 2.5;

  FreeCameraController(this.threeJs);

  void initialize() {
    try {
      final cam = threeJs.camera;
      // DEFINIÇÃO ÚNICA: Define a ordem YXZ (padrão para FPS/Editor).
      // Isso garante que a rotação Y (olhar para lados) aconteça no eixo global,
      // e a rotação X (olhar cima/baixo) aconteça no eixo local.
      cam.rotation.order = three.RotationOrders.yxz;
      
      // Garante que começamos nivelados
      cam.rotation.z = 0;
      cam.up.setValues(0, 1, 0);
      cam.updateMatrix();
    } catch (_) {}

    threeJs.addAnimationEvent(_update);
  }

  // --- Manipulação de Mouse ---

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

    
    // Rotação da Câmera (Mouse Look)
    cam.rotation.y -= e.delta.dx * 0.0025 * lookSpeed;
    cam.rotation.x -= e.delta.dy * 0.0025 * lookSpeed;

    const double maxPitch = 1.50;
    if (cam.rotation.x > maxPitch) cam.rotation.x = maxPitch;
    if (cam.rotation.x < -maxPitch) cam.rotation.x = -maxPitch;

    cam.rotation.z = 0;
    
    cam.updateMatrix();
  }


  void _update(double dt) {
    if (!rightMouseDown) return;

    final input = InputManager.instance;
    final cam = threeJs.camera;

    double speed = baseSpeed * dt;
    if (input.isKeyDown(LogicalKeyboardKey.shiftLeft) ||
        input.isKeyDown(LogicalKeyboardKey.shiftRight)) {
      speed *= runMultiplier;
    }


    final forward = three.Vector3.zero();
    cam.getWorldDirection(forward);
    forward.normalize();

    // 2. Right (Vetor lateral, sempre paralelo ao chão para strafe confortável)
    final right = three.Vector3(0, 1, 0).cross(forward);
    right.normalize();

    // --- MOVIMENTAÇÃO WASD ---

    if (input.isKeyDown(LogicalKeyboardKey.keyW)) {
      cam.position.addScaled(forward, speed);
    }
    if (input.isKeyDown(LogicalKeyboardKey.keyS)) {
      cam.position.addScaled(forward, -speed);
    }

    if (input.isKeyDown(LogicalKeyboardKey.keyA)) {
      cam.position.addScaled(right, speed);
    }
    if (input.isKeyDown(LogicalKeyboardKey.keyD)) {
      cam.position.addScaled(right, -speed);
    }

    // Q/E: Sobe e Desce absoluto (Elevador)
    if (input.isKeyDown(LogicalKeyboardKey.keyE)) {
      cam.position.y += speed;
    }
    if (input.isKeyDown(LogicalKeyboardKey.keyQ)) {
      cam.position.y -= speed;
    }
  }

  void dispose() {
    // Limpeza se necessário
  }
}