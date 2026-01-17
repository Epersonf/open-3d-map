import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../game_component.dart';
import '../../../domain/scene/scene_context.dart';
import 'light_enums.dart';
import 'ui/light_inspector.dart';

part 'light_component.g.dart';

@JsonSerializable()
class LightComponent extends GameComponent {
  static const String typeId = 'light';

  @override
  String get id => typeId;

  // General
  final LightType type;
  final int color;
  final double intensity;

  // Point/Spot
  final double range;

  // Spot
  final double spotAngle;
  final double spotPenumbra;

  // Area
  final double areaWidth;
  final double areaHeight;

  LightComponent({
    this.type = LightType.point,
    this.color = 0xFFFFFF,
    this.intensity = 1.0,
    this.range = 10.0,
    this.spotAngle = 45.0,
    this.spotPenumbra = 0.0,
    this.areaWidth = 5.0,
    this.areaHeight = 5.0,
  });

  factory LightComponent.fromJson(Map<String, dynamic> json) =>
      _$LightComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LightComponentToJson(this);

  @override
  LightComponent copyWith({
    LightType? type,
    int? color,
    double? intensity,
    double? range,
    double? spotAngle,
    double? spotPenumbra,
    double? areaWidth,
    double? areaHeight,
  }) {
    return LightComponent(
      type: type ?? this.type,
      color: color ?? this.color,
      intensity: intensity ?? this.intensity,
      range: range ?? this.range,
      spotAngle: spotAngle ?? this.spotAngle,
      spotPenumbra: spotPenumbra ?? this.spotPenumbra,
      areaWidth: areaWidth ?? this.areaWidth,
      areaHeight: areaHeight ?? this.areaHeight,
    );
  }

  @override
  Widget inspectorWidget() => const LightInspector();

  @override
  void onStart(SceneContext owner) {
  }

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    if (oldComponent is LightComponent) {
      if (oldComponent.type != type) {
        return true;
      }

      return true;
    }
    return false;
  }

  @override
  void onDestroy(SceneContext owner) {
  }
}
