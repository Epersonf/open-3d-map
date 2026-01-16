import 'package:flutter/widgets.dart';
import '../../domain/scene/game_component.dart' as domain_core;

typedef InspectorFactory = Widget Function(domain_core.GameComponent component);

class ComponentRegistry {
  // Delegates data factories to the domain registry
  // and keeps a map of inspector builders per component Type.
  static final Map<Type, InspectorFactory> _inspectorFactories = {};

  /// Register data factory in domain registry and inspector builder here.
  static void register<T extends domain_core.GameComponent>({
    required String typeId,
    required domain_core.ComponentFactory factory,
    required InspectorFactory inspectorBuilder,
  }) {
    domain_core.ComponentRegistry.register(typeId, factory);
    _inspectorFactories[T] = inspectorBuilder;
  }

  /// Build inspector widget for a concrete component instance
  static Widget createInspector(domain_core.GameComponent component) {
    final builder = _inspectorFactories[component.runtimeType];
    if (builder == null) {
      return Text('No inspector for ${component.runtimeType}');
    }
    return builder(component);
  }
}
