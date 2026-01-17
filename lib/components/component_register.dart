import 'package:open_3d_mapper/components/inherited/tags/tags_component.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/components/inherited/mesh/mesh_component.dart';
import 'package:open_3d_mapper/components/inherited/icon/icon_component.dart';
import 'package:open_3d_mapper/components/inherited/light/light_component.dart';
import 'package:open_3d_mapper/components/inherited/collider/collider_component.dart';
import 'package:open_3d_mapper/components/component_registry.dart';

class ComponentRegister {
  static void registerAll() {
    ComponentRegistry.register(
      TagsComponent.typeId,
      displayName: 'Tags & Layers',
      fromJson: (json) => TagsComponent.fromJson(json),
      createDefault: () => TagsComponent(),
    );

    ComponentRegistry.register(
      TransformComponent.typeId,
      displayName: 'Transform',
      fromJson: (json) => TransformComponent.fromJson(json),
      createDefault: () => TransformComponent.defaultValue(),
    );

    ComponentRegistry.register(
      MeshComponent.typeId,
      displayName: 'Mesh Renderer',
      fromJson: (json) => MeshComponent.fromJson(json),
      createDefault: () => MeshComponent(visibleInRuntime: true),
    );

    ComponentRegistry.register(
      IconComponent.typeId,
      displayName: 'Icon Visualization',
      fromJson: (json) => IconComponent.fromJson(json),
      createDefault: () => IconComponent(iconName: 'help'),
    );

    ComponentRegistry.register(
      LightComponent.typeId,
      displayName: 'Light Source',
      fromJson: (json) => LightComponent.fromJson(json),
      createDefault: () => LightComponent(),
    );

    // --- Register Collider ---
    ComponentRegistry.register(
      ColliderComponent.typeId,
      displayName: 'Collider',
      fromJson: (json) => ColliderComponent.fromJson(json),
      createDefault: () => ColliderComponent.createDefault(),
    );
  }
}
