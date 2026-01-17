import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';
import 'game_object/game_object.dart';

part 'scene.g.dart';

@JsonSerializable(explicitToJson: true)
class Scene {
  final String id;
  String name;

  /// Observable root objects list. Use `objects` as alias for compatibility.
  final ObservableList<GameObject> rootObjects;

  Scene({required this.id, required this.name, List<GameObject>? rootObjects})
      : rootObjects = ObservableList.of(rootObjects ?? []);

  /// Backwards-compatible alias used by some codepaths
  ObservableList<GameObject> get objects => rootObjects;

  factory Scene.fromJson(Map<String, dynamic> json) => _$SceneFromJson(json);
  Map<String, dynamic> toJson() => _$SceneToJson(this);
}
