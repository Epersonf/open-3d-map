// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameObject _$GameObjectFromJson(Map<String, dynamic> json) => GameObject(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      assetId: json['assetId'] as String?,
      transform: Transform.fromJson(json['transform'] as Map<String, dynamic>),
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => GameObject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GameObjectToJson(GameObject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentId': instance.parentId,
      'assetId': instance.assetId,
      'transform': instance.transform.toJson(),
      'tags': instance.tags,
      'children': instance.children.map((e) => e.toJson()).toList(),
    };
