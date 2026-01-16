import 'package:flutter/material.dart';

// O contrato para qualquer componente
abstract class GameComponent {
  String get id; // identificador do tipo do componente (ex: 'visual', 'tags')

  Map<String, dynamic> toJson();

  // Método auxiliar para criar cópias (imutabilidade)
  GameComponent copyWith();

  // --- Ciclo de vida ---
  /// Chamado quando o componente é inicializado ou adicionado à cena
  void onStart(dynamic owner) {}

  /// Chamado a cada frame do loop (delta time em segundos)
  void onUpdate(dynamic owner, double dt) {}

  /// Chamado quando o componente/owner é destruído
  void onDestroy(dynamic owner) {}

  Widget inspectorWidget() {
    return Text('No inspector for $id');
  }
}

// Registry para criar componentes a partir do JSON sem switch-case
typedef ComponentFactory = GameComponent Function(Map<String, dynamic> json);

class ComponentRegistry {
  static final Map<String, ComponentFactory> _factories = {};

  static void register<T extends GameComponent>(
      String id, ComponentFactory factory) {
    _factories[id] = factory;
  }

  static GameComponent create(String id, Map<String, dynamic> json) {
    final factory = _factories[id];
    if (factory == null) {
      throw Exception("Component type '$id' not registered.");
    }
    return factory(json);
  }
}
