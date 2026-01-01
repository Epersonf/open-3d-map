import 'package:json_annotation/json_annotation.dart';

part 'asset.g.dart';

@JsonSerializable(explicitToJson: true)
class Asset {
  final String id;
  final String path;
  final String type;

  Asset({required this.id, required this.path, required this.type});

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
  Map<String, dynamic> toJson() => _$AssetToJson(this);
}
