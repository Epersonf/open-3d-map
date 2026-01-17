import 'package:mobx/mobx.dart';
import 'game_component.dart';

class GameObject {
  final String id;
  String name;
  String? parentId;

  /// A única fonte de verdade: lista de componentes
  final List<GameComponent> components;

  /// Observable children list so MobX observers detect add/remove
  final ObservableList<GameObject> children;

  GameObject({
    required this.id,
    required this.name,
    this.parentId,
    Map<String, String>? tags,
    List<GameComponent>? components,
    List<GameObject>? children,
  })  : components = components ?? [],
        children = ObservableList.of(children ?? []) {
  }

  // --- Component helpers ---
  T? getComponent<T extends GameComponent>() {
    for (final c in components) {
      if (c is T) return c;
    }
    return null;
  }

  GameComponent? getComponentById(String id) {
    try {
      return components.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void setComponent<T extends GameComponent>(T component) {
    components.removeWhere((c) => c.id == component.id);
    components.add(component);
  }

  /// Return a new GameObject with the given component replaced/added (immutable helper)
  GameObject copyWithComponent(GameComponent newComponent) {
    final newComponents = components.where((c) => c.id != newComponent.id).toList();
    newComponents.add(newComponent);

    return GameObject(
      id: id,
      name: name,
      parentId: parentId,
      components: newComponents,
      children: children,
    );
  }

  void addChild(GameObject child) {
    child.parentId = id;
    children.add(child);
  }

  void removeChild(String childId) {
    children.removeWhere((c) => c.id == childId);
  }

  // --- Manual JSON (polymorphic components) ---
  factory GameObject.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final parentId = json['parentId'] as String?;

    final List<GameComponent> comps = [];
    if (json['components'] != null) {
      final compMap = json['components'] as Map<String, dynamic>;
      compMap.forEach((typeId, data) {
        try {
          final c = ComponentRegistry.create(typeId, data as Map<String, dynamic>);
          comps.add(c);
        } catch (e) {
          // ignore unknown component types
        }
      });
    }

    final kids = <GameObject>[];
    if (json['children'] != null) {
      final list = json['children'] as List;
      kids.addAll(list.map((c) => GameObject.fromJson(c as Map<String, dynamic>)));
    }

    return GameObject(id: id, name: name, parentId: parentId, components: comps, children: kids);
  }

  Map<String, dynamic> toJson() {
    final compsMap = <String, dynamic>{};
    for (final c in components) {
      compsMap[c.id] = c.toJson();
    }

    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'components': compsMap,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}
