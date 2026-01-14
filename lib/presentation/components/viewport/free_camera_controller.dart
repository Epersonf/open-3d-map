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
    // NOTA: Não acessar `threeJs.camera` aqui — a câmera pode não
    // estar inicializada quando o controller for criado (ex: initState).
    // A configuração dependente da câmera deve ser feita em `initialize()`.
  }

  /// Inicializa partes que dependem da existência da câmera.
  /// Deve ser chamada depois que a cena/câmera do ThreeJS estiver pronta.
  void initialize() {
    try {
      final cam = threeJs.camera;
      cam.rotation.order = three.RotationOrders.yxz;
    } catch (_) {
      // Se a câmera ainda não estiver pronta, ignoramos —
      // o chamador deve garantir que `initialize()` seja executado
      // assim que a cena estiver disponível.
    }

    // Registra o loop de atualização (mesmo se a câmera ainda não estiver configurada,
    // `_update` só acessará a câmera quando necessário durante o loop).
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

    // Garante que a ordem não foi perdida (ex: após um lookAt)
    if (cam.rotation.order != three.RotationOrders.yxz) {
      cam.rotation.order = three.RotationOrders.yxz;
      cam.updateMatrix();
    }

    // Y = Yaw (Esquerda/Direita global)
    cam.rotation.y -= e.delta.dx * 0.0025 * lookSpeed;

    // X = Pitch (Cima/Baixo local)
    cam.rotation.x -= e.delta.dy * 0.0025 * lookSpeed;

    // Trava para não dar cambalhota (olhar para trás por cima da cabeça)
    const double maxPitch = 1.50; // aprox 85 graus
    if (cam.rotation.x > maxPitch) cam.rotation.x = maxPitch;
    if (cam.rotation.x < -maxPitch) cam.rotation.x = -maxPitch;

    // Força Z a zero e realinha o vetor UP
    cam.rotation.z = 0;
    cam.up.setValues(0, 1, 0);
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
    // Permite movimento por teclado mesmo sem o botão direito pressionado
    if (!rightMouseDown && keys.isEmpty) return;

    final cam = threeJs.camera;

    double speed = baseSpeed * dt;
    if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight)) {
      speed *= runMultiplier;
    }

    // Pega a direção que a câmera está olhando
    final forward = three.Vector3.zero();
    cam.getWorldDirection(forward);
    forward.y = 0; // Zera a inclinação Y para andar apenas no plano horizontal
    forward.normalize();

    // Calcula o vetor da direita (Right)
    final right = three.Vector3(0, 1, 0).cross(forward);
    right.normalize();

    if (keys.contains(LogicalKeyboardKey.keyW)) {
      cam.position.addScaled(forward, speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyS)) {
      cam.position.addScaled(forward, -speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyA)) {
      cam.position.addScaled(right, speed);
    }
    if (keys.contains(LogicalKeyboardKey.keyD)) {
      cam.position.addScaled(right, -speed);
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
