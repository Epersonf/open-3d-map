import 'package:open_3d_mapper/components/game_component.dart';

/// Factory typedefs for component creation
typedef ComponentFactory = GameComponent Function(Map<String, dynamic> json);
typedef DefaultFactory = GameComponent Function();

/// Metadata holder for components used by the editor/UI
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
