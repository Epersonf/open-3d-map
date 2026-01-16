import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_inspector.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import '../../../domain/scene/game_component.dart';

part 'transform_component.g.dart';

@JsonSerializable(explicitToJson: true)
class TransformComponent extends GameComponent {
  static const String typeId = 'transform';

  @override
  String get id => typeId;

  
  final Vec3 position;
  final Vec3 rotation;
  final Vec3 scale;

  TransformComponent({
    required this.position,
    required this.rotation,
    required this.scale,
  });

  factory TransformComponent.defaultValue() {
    return TransformComponent(
      position: Vec3(x: 0, y: 0, z: 0),
      rotation: Vec3(x: 0, y: 0, z: 0),
      scale: Vec3(x: 1, y: 1, z: 1),
    );
  }

  factory TransformComponent.fromJson(Map<String, dynamic> json) => _$TransformComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TransformComponentToJson(this);

  @override
  TransformComponent copyWith({
    Vec3? position,
    Vec3? rotation,
    Vec3? scale,
  }) {
    return TransformComponent(
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }

  @override
  void onStart(dynamic owner) {
    // Default: no-op
  }

  @override
  void onUpdate(dynamic owner, double dt) {
    // Default: no-op
  }

  @override
  Widget inspectorWidget() {
    return TransformInspector();
  }
}
