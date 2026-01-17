import 'package:open_3d_mapper/domain/scene/game_component.dart';

import 'component_definition.dart';

class ComponentRegistry {
  static final Map<String, ComponentDefinition> _definitions = {};

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

  static GameComponent create(String id, Map<String, dynamic> json) {
    final def = _definitions[id];
    if (def == null) throw Exception("Component type '$id' not registered.");
    return def.factoryFromJson(json);
  }

  static GameComponent createDefault(String id) {
    final def = _definitions[id];
    if (def == null) throw Exception("Component type '$id' not registered.");
    return def.factoryDefault();
  }

  static Map<String, String> getAvailableComponents() {
    return {for (var e in _definitions.entries) e.key: e.value.displayName};
  }
}
