// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagsComponent _$TagsComponentFromJson(Map<String, dynamic> json) =>
    TagsComponent(
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$TagsComponentToJson(TagsComponent instance) =>
    <String, dynamic>{
      'tags': instance.tags,
    };
