import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';
import 'transform.dart';

part 'game_object.g.dart';

@JsonSerializable(explicitToJson: true)
class GameObject {
  final String id;
  String name;
  String? parentId;
  final String? assetId;
  final Transform transform;
  final Map<String, String> tags;

  // Observable children list so MobX observers detect add/remove
  final ObservableList<GameObject> children;

  GameObject({
    required this.id,
    required this.name,
    this.parentId,
    this.assetId,
    required this.transform,
    Map<String, String>? tags,
    List<GameObject>? children,
  })  : tags = tags ?? {},
        children = ObservableList.of(children ?? []);

  // Helpers to maintain reactivity
  void addChild(GameObject child) {
    child.parentId = id;
    children.add(child);
  }

  void removeChild(String childId) {
    children.removeWhere((c) => c.id == childId);
  }

  factory GameObject.fromJson(Map<String, dynamic> json) => _$GameObjectFromJson(json);
  Map<String, dynamic> toJson() => _$GameObjectToJson(this);
}
