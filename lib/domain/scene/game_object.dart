import 'package:json_annotation/json_annotation.dart';
import 'transform.dart';

part 'game_object.g.dart';

@JsonSerializable(explicitToJson: true)
class GameObject {
  final String id;
  final String name;
  final String? parentId;
  final String? assetId;
  final Transform transform;
  final Map<String, String> tags;
  final List<GameObject> children;

  GameObject({
    required this.id,
    required this.name,
    this.parentId,
    this.assetId,
    required this.transform,
    Map<String, String>? tags,
    List<GameObject>? children,
  })  : tags = tags ?? {},
        children = children ?? [];

  factory GameObject.fromJson(Map<String, dynamic> json) => _$GameObjectFromJson(json);
  Map<String, dynamic> toJson() => _$GameObjectToJson(this);
}
