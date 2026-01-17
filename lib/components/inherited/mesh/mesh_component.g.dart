// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesh_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeshComponent _$MeshComponentFromJson(Map<String, dynamic> json) =>
    MeshComponent(
      assetId: json['assetId'] as String?,
      visibleInRuntime: json['visibleInRuntime'] as bool? ?? true,
    );

Map<String, dynamic> _$MeshComponentToJson(MeshComponent instance) =>
    <String, dynamic>{
      'assetId': instance.assetId,
      'visibleInRuntime': instance.visibleInRuntime,
    };
