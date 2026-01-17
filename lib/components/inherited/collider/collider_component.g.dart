// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collider_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColliderComponent _$ColliderComponentFromJson(Map<String, dynamic> json) =>
    ColliderComponent(
      type: $enumDecodeNullable(_$ColliderTypeEnumMap, json['type']) ??
          ColliderType.box,
      center: Vec3.fromJson(json['center'] as Map<String, dynamic>),
      size: Vec3.fromJson(json['size'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble() ?? 0.5,
      isTrigger: json['isTrigger'] as bool? ?? false,
      convex: json['convex'] as bool? ?? true,
    );

Map<String, dynamic> _$ColliderComponentToJson(ColliderComponent instance) =>
    <String, dynamic>{
      'type': _$ColliderTypeEnumMap[instance.type]!,
      'center': instance.center.toJson(),
      'isTrigger': instance.isTrigger,
      'size': instance.size.toJson(),
      'radius': instance.radius,
      'convex': instance.convex,
    };

const _$ColliderTypeEnumMap = {
  ColliderType.box: 'box',
  ColliderType.sphere: 'sphere',
};
