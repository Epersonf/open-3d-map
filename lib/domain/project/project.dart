import 'package:json_annotation/json_annotation.dart';
import '../asset/asset.dart';
import '../scene/scene.dart';

part 'project.g.dart';

@JsonSerializable(explicitToJson: true)
class Project {
  final int version;
  final String name;
  final String assetsFolder;
  final List<Asset> assets;
  final List<Scene> scenes;

  Project({required this.version, required this.name, required this.assetsFolder, required this.assets, required this.scenes});

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  static Project createNew(String name) => Project(version: 1, name: name, assetsFolder: 'assets', assets: [], scenes: []);
}
