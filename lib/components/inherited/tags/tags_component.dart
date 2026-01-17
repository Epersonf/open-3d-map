import 'package:flutter/material.dart';
import 'package:open_3d_mapper/components/inherited/tags/tags_inspector.dart';

import '../../game_component.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tags_component.g.dart';

@JsonSerializable()
class TagsComponent extends GameComponent {
  static const String typeId = 'tags';

  @override
  String get id => typeId;

  final Map<String, String> tags;

  TagsComponent({Map<String, String>? tags}) : tags = tags ?? {};

  factory TagsComponent.fromJson(Map<String, dynamic> json) =>
      _$TagsComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TagsComponentToJson(this);

  @override
  TagsComponent copyWith() => TagsComponent(tags: Map.from(tags));

  @override
  Widget inspectorWidget() {
    return TagsInspector();
  }
}
