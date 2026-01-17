// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icon_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IconComponent _$IconComponentFromJson(Map<String, dynamic> json) =>
    IconComponent(
      iconName: json['iconName'] as String? ?? 'spawn',
      iconSize: (json['iconSize'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$IconComponentToJson(IconComponent instance) =>
    <String, dynamic>{
      'iconName': instance.iconName,
      'iconSize': instance.iconSize,
    };
