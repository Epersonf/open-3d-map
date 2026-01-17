import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Singleton que distribui eventos de input para quem estiver interessado
/// (Ex: Gizmos, Câmera, Seleção, etc) sem que o Viewport precise conhecê-los.
class InputManager {
  static final InputManager instance = InputManager._();
  InputManager._();

  // --- Estado do teclado (polling) ---
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  /// Retorna true se a tecla estiver pressionada neste momento
  bool isKeyDown(LogicalKeyboardKey key) => _pressedKeys.contains(key);

  /// Chamado pelo Viewport quando uma tecla é pressionada ou solta
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  // Callbacks
  bool Function(PointerDownEvent, Size)? _onPointerDown;
  void Function(PointerMoveEvent)? _onPointerMove;
  void Function()? _onPointerUp;

  /// Registra um handler prioritário (ex: Gizmo).
  /// Se retornar true, consome o evento.
  void registerPriorityHandler({
    bool Function(PointerDownEvent, Size)? onDown,
    void Function(PointerMoveEvent)? onMove,
    void Function()? onUp,
  }) {
    _onPointerDown = onDown;
    _onPointerMove = onMove;
    _onPointerUp = onUp;
  }

  // --- Métodos chamados pelo Viewport ---

  bool handlePointerDown(PointerDownEvent event, Size viewportSize) {
    if (_onPointerDown != null) {
      return _onPointerDown!(event, viewportSize);
    }
    return false;
  }

  void handlePointerMove(PointerMoveEvent event) {
    if (_onPointerMove != null) {
      _onPointerMove!(event);
    }
  }

  void handlePointerUp() {
    if (_onPointerUp != null) {
      _onPointerUp!();
    }
  }
}
