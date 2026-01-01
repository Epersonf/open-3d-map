import 'package:json_annotation/json_annotation.dart';

part 'transform.g.dart';

@JsonSerializable()
class Vec3 {
  final double x;
  final double y;
  final double z;

  Vec3({required this.x, required this.y, required this.z});

  factory Vec3.fromJson(Map<String, dynamic> json) => _$Vec3FromJson(json);
  Map<String, dynamic> toJson() => _$Vec3ToJson(this);
}

@JsonSerializable()
class Transform {
  final Vec3 position;
  final Vec3 rotation;
  final Vec3 scale;

  Transform({required this.position, required this.rotation, required this.scale});

  factory Transform.fromJson(Map<String, dynamic> json) => _$TransformFromJson(json);
  Map<String, dynamic> toJson() => _$TransformToJson(this);
}
