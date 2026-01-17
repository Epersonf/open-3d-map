import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:three_js/three_js.dart' as three;
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Light? _lightObject;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool _isDisposed = false;

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
    _isDisposed = false;
    _rebuildLight(owner);
  }

  void _rebuildLight(SceneContext owner) {
    if (_lightObject != null) {
      try {
        _lightObject!.removeFromParent();
      } catch (_) {}
      try {
        _lightObject!.dispose();
      } catch (_) {}
      _lightObject = null;
    }

    if (_isDisposed) return;

    switch (type) {
      case LightType.point:
        _lightObject = three.PointLight(color, intensity, range);
        break;
      case LightType.directional:
        final dirLight = three.DirectionalLight(color, intensity);
        final target = three.Object3D();
        target.position.setValues(0, 0, -1);
        dirLight.add(target);
        dirLight.target = target;
        _lightObject = dirLight;
        break;
      case LightType.spot:
        final radAngle = (spotAngle * 3.14159 / 180) / 2;
        final spot = three.SpotLight(color, intensity, range, radAngle, spotPenumbra);
        final target = three.Object3D();
        target.position.setValues(0, 0, -1);
        spot.add(target);
        spot.target = target;
        _lightObject = spot;
        break;
      case LightType.area:
        _lightObject = three.RectAreaLight(color, intensity, areaWidth, areaHeight);
        break;
    }

    if (_lightObject != null) {
      _lightObject!.name = 'Light_${type.name}';
      owner.parent.add(_lightObject!);
    }
  }

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    if (oldComponent is LightComponent) {
      if (oldComponent.type != type) {
        if (oldComponent._lightObject != null) {
          try {
            oldComponent._lightObject!.removeFromParent();
          } catch (_) {}
        }
        _rebuildLight(owner);
        return true;
      }

      _lightObject = oldComponent._lightObject;
      oldComponent._lightObject = null;

      if (_lightObject != null) {
        _applyProperties(_lightObject!);
      } else {
        _rebuildLight(owner);
      }

      return true;
    }
    return false;
  }

  void _applyProperties(three.Light light) {
    try {
      light.color = three.Color.fromHex32(color & 0xFFFFFF);
    } catch (_) {}
    try {
      light.intensity = intensity;
    } catch (_) {}

    if (light is three.PointLight) {
      try {
        light.distance = range;
      } catch (_) {}
    } else if (light is three.SpotLight) {
      try {
        light.distance = range;
        light.angle = (spotAngle * 3.14159 / 180) / 2;
        light.penumbra = spotPenumbra;
      } catch (_) {}
    } else if (light is three.RectAreaLight) {
      try {
        light.width = areaWidth;
        light.height = areaHeight;
      } catch (_) {}
    }
  }

  @override
  void onDestroy(SceneContext owner) {
    _isDisposed = true;
    if (_lightObject != null) {
      try {
        _lightObject!.removeFromParent();
      } catch (_) {}
      try {
        _lightObject!.dispose();
      } catch (_) {}
      _lightObject = null;
    }
  }
}
