import 'package:flutter/material.dart';
import 'package:open_3d_mapper/domain/scene/scene_context.dart';

abstract class GameComponent {
  String get id;

  Map<String, dynamic> toJson();

  GameComponent copyWith();

  void onStart(SceneContext owner) {}

  void onUpdate(SceneContext owner, double dt) {}

  void onDestroy(SceneContext owner) {}

  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) => false;

  void onSelected(SceneContext owner) {}

  void onDeselected(SceneContext owner) {}

  Widget inspectorWidget() {
    return Text('No inspector for $id');
  }
}

typedef ComponentFactory = GameComponent Function(Map<String, dynamic> json);
typedef DefaultFactory = GameComponent Function();

class ComponentDefinition {
  final String displayName;
  final ComponentFactory factoryFromJson;
  final DefaultFactory factoryDefault;

  ComponentDefinition({
    required this.displayName,
    required this.factoryFromJson,
    required this.factoryDefault,
  });
}

class ComponentRegistry {
  static final Map<String, ComponentDefinition> _definitions = {};

  /// Registra um componente com metadados para a UI e Factories
  static void register(
    String typeId, {
    required String displayName,
    required ComponentFactory fromJson,
    required DefaultFactory createDefault,
  }) {
    _definitions[typeId] = ComponentDefinition(
      displayName: displayName,
      factoryFromJson: fromJson,
      factoryDefault: createDefault,
    );
  }

  /// Cria a partir do JSON (Load)
  static GameComponent create(String id, Map<String, dynamic> json) {
    final def = _definitions[id];
    if (def == null) {
      throw Exception("Component type '$id' not registered.");
    }
    return def.factoryFromJson(json);
  }

  /// Cria uma instância padrão (Add Component Button)
  static GameComponent createDefault(String id) {
    final def = _definitions[id];
    if (def == null) {
      throw Exception("Component type '$id' not registered.");
    }
    return def.factoryDefault();
  }

  /// Retorna lista de componentes disponíveis para a UI
  /// Map<TypeId, DisplayName>
  static Map<String, String> getAvailableComponents() {
    return {
      for (var entry in _definitions.entries) entry.key: entry.value.displayName
    };
  }
}
