import 'package:open_3d_mapper/components/inherited/tags/tags_component.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/components/inherited/visual/visual_component.dart';
import 'package:open_3d_mapper/domain/scene/game_component.dart';

class ComponentRegister {
  static void registerAll() {
    ComponentRegistry.register(
      VisualComponent.typeId,
      (json) => VisualComponent.fromJson(json),
    );

    ComponentRegistry.register(
      TagsComponent.typeId,
      (json) => TagsComponent.fromJson(json),
    );

    ComponentRegistry.register(
      TransformComponent.typeId,
      (json) => TransformComponent.fromJson(json),
    );
  }
}
