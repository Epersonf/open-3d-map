import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:open_3d_mapper/core/input/input_manager.dart'; // Ajuste o import conforme seu projeto

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
      cam.rotation.order = three.RotationOrders.yxz;
    } catch (_) {}

    threeJs.addAnimationEvent(_update);
  }

  // --- Manipulação de Mouse ---
  // Esses métodos devem ser chamados pelo seu Widget/Viewport 
  // quando o InputManager não consumir o evento (ex: Gizmo não clicado)

  void onPointerDown(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.mouse &&
        e.buttons == kSecondaryMouseButton) {
      rightMouseDown = true;
    }
  }

  void onPointerUp(PointerUpEvent e) {
    if (e.kind == PointerDeviceKind.mouse) {
      // Se soltar qualquer botão e for o direito, paramos
      // (nota: em alguns casos pode querer verificar se foi especificamente o direito)
      rightMouseDown = false;
    }
  }

  void onPointerMove(PointerMoveEvent e) {
    if (!rightMouseDown) return;

    final cam = threeJs.camera;

    if (cam.rotation.order != three.RotationOrders.yxz) {
      cam.rotation.order = three.RotationOrders.yxz;
      cam.updateMatrix();
    }

    // Rotação da Câmera (Mouse Look)
    cam.rotation.y -= e.delta.dx * 0.0025 * lookSpeed;
    cam.rotation.x -= e.delta.dy * 0.0025 * lookSpeed;

    const double maxPitch = 1.50; 
    if (cam.rotation.x > maxPitch) cam.rotation.x = maxPitch;
    if (cam.rotation.x < -maxPitch) cam.rotation.x = -maxPitch;

    cam.rotation.z = 0;
    cam.up.setValues(0, 1, 0);
  }

  // --- Loop de Atualização (Frame a Frame) ---

  void _update(double dt) {
    // REGRA: Só movimenta se o botão direito estiver segurado
    if (!rightMouseDown) return;

    final input = InputManager.instance;
    final cam = threeJs.camera;

    // Velocidade
    double speed = baseSpeed * dt;
    if (input.isKeyDown(LogicalKeyboardKey.shiftLeft) ||
        input.isKeyDown(LogicalKeyboardKey.shiftRight)) {
      speed *= runMultiplier;
    }

    // --- CÁLCULO DOS VETORES DE DIREÇÃO ---

    // 1. Forward (Para onde a câmera aponta em 3D)
    final forward = three.Vector3.zero();
    cam.getWorldDirection(forward);
    forward.normalize(); 
    // REMOVIDO: forward.y = 0; -> Isso permitia andar apenas no chão. 
    // Agora 'forward' aponta exatamente para onde você olha.

    // 2. Right (Vetor lateral, sempre paralelo ao chão para strafe confortável)
    // Para o strafe (A/D), geralmente queremos manter o movimento horizontal 
    // para não "afundar" no chão ao andar de lado olhando para baixo.
    final right = three.Vector3(0, 1, 0).cross(forward); 
    right.normalize();

    // --- MOVIMENTAÇÃO WASD ---
    
    // W/S: Move na direção do olhar (sobe se olhar pra cima, desce se olhar pra baixo)
    if (input.isKeyDown(LogicalKeyboardKey.keyW)) {
      cam.position.addScaled(forward, speed);
    }
    if (input.isKeyDown(LogicalKeyboardKey.keyS)) {
      cam.position.addScaled(forward, -speed);
    }

    // A/D: Move lateralmente (Strafe)
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
    // Se necessário remover o listener do tick, faça aqui se a lib permitir
  }
}