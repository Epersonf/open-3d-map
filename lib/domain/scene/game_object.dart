import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';
import 'transform.dart';
import 'visual_component.dart';
import 'game_component.dart';
import 'tags_component.dart';

part 'game_object.g.dart';

@JsonSerializable(explicitToJson: true)
class GameObject {
  final String id;
  String name;
  String? parentId;
  final VisualComponent visual;
  final Transform transform;
  final Map<String, String> tags;

  // Lista polimórfica de componentes (não serializada por enquanto)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<GameComponent> components;

  // Observable children list so MobX observers detect add/remove
  final ObservableList<GameObject> children;

  GameObject({
    required this.id,
    required this.name,
    this.parentId,
    VisualComponent? visual,
    required this.transform,
    Map<String, String>? tags,
    List<GameObject>? children,
    List<GameComponent>? components,
  })  : tags = tags ?? {},
        visual = visual ?? VisualComponent(type: VisualType.none),
        children = ObservableList.of(children ?? []),
        components = components ?? [];

  // Helpers to maintain reactivity
  void addChild(GameObject child) {
    child.parentId = id;
    children.add(child);
  }

  void removeChild(String childId) {
    children.removeWhere((c) => c.id == childId);
  }

  /// Retorna o primeiro componente do tipo T
  T? getComponent<T extends GameComponent>() {
    for (final c in components) {
      if (c is T) return c as T;
    }

    // Fallbacks para compatibilidade com o modelo antigo
    if (T == VisualComponent) {
      return visual as T;
    }
    if (T == TagsComponent) {
      return TagsComponent(tags: Map.from(tags)) as T;
    }

    return null;
  }

  /// Substitui ou adiciona um componente; sincroniza campos legados quando possível
  void setComponent<T extends GameComponent>(T component) {
    // Remove existente do mesmo tipo
    components.removeWhere((c) => c.runtimeType == component.runtimeType);
    components.add(component);

    // Sincroniza com campos legados para compatibilidade
    if (component is VisualComponent) {
      // visual é final; não podemos reassignar. No modelo atual mantemos visual separado.
      // Para compatibilidade, se o visual interno for default (none) atualize via reflection
      // (Aqui mantemos visual como a fonte de verdade para serialização antiga.)
    }
    if (component is TagsComponent) {
      tags
        ..clear()
        ..addAll(component.tags);
    }
  }

  factory GameObject.fromJson(Map<String, dynamic> json) => _$GameObjectFromJson(json);
  Map<String, dynamic> toJson() => _$GameObjectToJson(this);
}
