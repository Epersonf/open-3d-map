import 'package:json_annotation/json_annotation.dart';
import 'game_object.dart';

part 'scene.g.dart';

@JsonSerializable(explicitToJson: true)
class Scene {
  final String id;
  final String name;
  final List<GameObject> rootObjects;

  Scene({required this.id, required this.name, required this.rootObjects});

  factory Scene.fromJson(Map<String, dynamic> json) => _$SceneFromJson(json);
  Map<String, dynamic> toJson() => _$SceneToJson(this);
}
