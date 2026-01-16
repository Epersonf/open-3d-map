// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visual_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VisualComponent _$VisualComponentFromJson(Map<String, dynamic> json) =>
    VisualComponent(
      type: $enumDecodeNullable(_$VisualTypeEnumMap, json['type']) ??
          VisualType.none,
      assetId: json['assetId'] as String?,
      iconName: json['iconName'] as String?,
      visibleInRuntime: json['visibleInRuntime'] as bool? ?? true,
    );

Map<String, dynamic> _$VisualComponentToJson(VisualComponent instance) =>
    <String, dynamic>{
      'type': _$VisualTypeEnumMap[instance.type]!,
      'assetId': instance.assetId,
      'iconName': instance.iconName,
      'visibleInRuntime': instance.visibleInRuntime,
    };

const _$VisualTypeEnumMap = {
  VisualType.mesh: 'mesh',
  VisualType.icon: 'icon',
  VisualType.none: 'none',
};
