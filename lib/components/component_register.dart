import 'package:open_3d_mapper/components/inherited/tags/tags_component.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/components/inherited/mesh/mesh_component.dart';
import 'package:open_3d_mapper/components/inherited/icon/icon_component.dart';
import 'package:open_3d_mapper/components/inherited/mesh/mesh_component.dart';
import 'package:open_3d_mapper/components/inherited/icon/icon_component.dart';
import 'package:open_3d_mapper/domain/scene/game_component.dart';

class ComponentRegister {
  static void registerAll() {
    ComponentRegistry.register(
      TagsComponent.typeId,
      (json) => TagsComponent.fromJson(json),
    );

    ComponentRegistry.register(
      TransformComponent.typeId,
      (json) => TransformComponent.fromJson(json),
    );
    ComponentRegistry.register(
      MeshComponent.typeId,
      (json) => MeshComponent.fromJson(json),
    );

    ComponentRegistry.register(
      IconComponent.typeId,
      (json) => IconComponent.fromJson(json),
    );
  }
}
