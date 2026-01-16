// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transform_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransformComponent _$TransformComponentFromJson(Map<String, dynamic> json) =>
    TransformComponent(
      position: Vec3.fromJson(json['position'] as Map<String, dynamic>),
      rotation: Vec3.fromJson(json['rotation'] as Map<String, dynamic>),
      scale: Vec3.fromJson(json['scale'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TransformComponentToJson(TransformComponent instance) =>
    <String, dynamic>{
      'position': instance.position.toJson(),
      'rotation': instance.rotation.toJson(),
      'scale': instance.scale.toJson(),
    };
