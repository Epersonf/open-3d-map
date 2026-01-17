import 'package:flutter/material.dart';
import 'package:open_3d_mapper/components/inherited/tags/tags_inspector.dart';
import 'package:open_3d_mapper/domain/scene/game_object/game_object.dart';

import '../../../domain/scene/game_component.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tags_component.g.dart';

@JsonSerializable()
class TagsComponent implements GameComponent {
  static const String typeId = 'tags';

  @override
  String get id => typeId;

  final Map<String, String> tags;

  TagsComponent({Map<String, String>? tags}) : tags = tags ?? {};

  factory TagsComponent.fromJson(Map<String, dynamic> json) => _$TagsComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TagsComponentToJson(this);

  @override
  TagsComponent copyWith() => TagsComponent(tags: Map.from(tags));
  
  @override
  void onDestroy(owner) {}
  
  @override
  void onStart(owner) {}
  
  @override
  void onUpdate(owner, double dt) {}

  @override
  Widget inspectorWidget() {
    return TagsInspector();
  }
  
  @override
  void onDeselected(owner) {}
  
  @override
  void onSelected(owner) {}
  
  @override
  bool onDidUpdate(GameComponent oldComponent, owner) {
    return false;
  }

  @override
  GameComponent onReparent(GameObject self, GameObject? oldParent, GameObject? newParent, Map<String, GameObject> objectLookup) {
    return this;
  }
}
