// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
      version: (json['version'] as num).toInt(),
      name: json['name'] as String,
      assetsFolder: json['assetsFolder'] as String,
      assets: (json['assets'] as List<dynamic>)
          .map((e) => Asset.fromJson(e as Map<String, dynamic>))
          .toList(),
      scenes: (json['scenes'] as List<dynamic>)
          .map((e) => Scene.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'version': instance.version,
      'name': instance.name,
      'assetsFolder': instance.assetsFolder,
      'assets': instance.assets.map((e) => e.toJson()).toList(),
      'scenes': instance.scenes.map((e) => e.toJson()).toList(),
    };
