// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'light_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LightComponent _$LightComponentFromJson(Map<String, dynamic> json) =>
    LightComponent(
      type: $enumDecodeNullable(_$LightTypeEnumMap, json['type']) ??
          LightType.point,
      color: (json['color'] as num?)?.toInt() ?? 0xFFFFFF,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      range: (json['range'] as num?)?.toDouble() ?? 10.0,
      spotAngle: (json['spotAngle'] as num?)?.toDouble() ?? 45.0,
      spotPenumbra: (json['spotPenumbra'] as num?)?.toDouble() ?? 0.0,
      areaWidth: (json['areaWidth'] as num?)?.toDouble() ?? 5.0,
      areaHeight: (json['areaHeight'] as num?)?.toDouble() ?? 5.0,
    );

Map<String, dynamic> _$LightComponentToJson(LightComponent instance) =>
    <String, dynamic>{
      'type': _$LightTypeEnumMap[instance.type]!,
      'color': instance.color,
      'intensity': instance.intensity,
      'range': instance.range,
      'spotAngle': instance.spotAngle,
      'spotPenumbra': instance.spotPenumbra,
      'areaWidth': instance.areaWidth,
      'areaHeight': instance.areaHeight,
    };

const _$LightTypeEnumMap = {
  LightType.point: 'point',
  LightType.spot: 'spot',
  LightType.directional: 'directional',
  LightType.area: 'area',
};
