import 'package:json_annotation/json_annotation.dart';

part 'vec3.g.dart';

@JsonSerializable()
class Vec3 {
  final double x;
  final double y;
  final double z;

  Vec3({required this.x, required this.y, required this.z});

  factory Vec3.fromJson(Map<String, dynamic> json) => _$Vec3FromJson(json);
  Map<String, dynamic> toJson() => _$Vec3ToJson(this);
}