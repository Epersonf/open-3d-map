// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vec3 _$Vec3FromJson(Map<String, dynamic> json) => Vec3(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );

Map<String, dynamic> _$Vec3ToJson(Vec3 instance) => <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };

Transform _$TransformFromJson(Map<String, dynamic> json) => Transform(
      position: Vec3.fromJson(json['position'] as Map<String, dynamic>),
      rotation: Vec3.fromJson(json['rotation'] as Map<String, dynamic>),
      scale: Vec3.fromJson(json['scale'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TransformToJson(Transform instance) => <String, dynamic>{
      'position': instance.position,
      'rotation': instance.rotation,
      'scale': instance.scale,
    };
