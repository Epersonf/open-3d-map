import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:open_3d_mapper/domain/scene/game_object/game_object.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../domain/scene/game_component.dart';
import '../../../domain/scene/scene_context.dart';
import '../../../core/utils/icon_texture_generator.dart';
import 'icon_inspector.dart';

part 'icon_component.g.dart';

@JsonSerializable()
class IconComponent implements GameComponent {
  static const String typeId = 'icon';

  @override
  String get id => typeId;

  final String iconName;

  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Object3D? _sprite;

  IconComponent({this.iconName = 'spawn'});

  factory IconComponent.fromJson(Map<String, dynamic> json) => _$IconComponentFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$IconComponentToJson(this);

  @override
  IconComponent copyWith({String? iconName}) => IconComponent(iconName: iconName ?? this.iconName);

  @override
  Widget inspectorWidget() => const IconInspector();

  @override
  void onStart(SceneContext owner) async {
    if (_sprite != null) {
      if (_sprite!.parent != owner.parent) {
        owner.parent.add(_sprite!);
      }
      return;
    }

    IconData iconData = Icons.help_outline;
    switch (iconName) {
      case 'light': iconData = Icons.lightbulb; break;
      case 'camera': iconData = Icons.videocam; break;
      case 'spawn': iconData = Icons.flag; break;
      case 'enemy': iconData = Icons.bug_report; break;
    }

    final texture = await IconTextureGenerator.createTextureFromIcon(
      iconData,
      size: 128,
      color: Colors.white,
    );

    final material = three.SpriteMaterial();
    material.map = texture;
    material.color = three.Color.fromHex32(0xFFFFFF);
    material.transparent = true;
    material.alphaTest = 0.5;

    _sprite = three.Sprite(material);
    _sprite!.scale.setValues(0.5, 0.5, 0.5);
    owner.parent.add(_sprite!);
  }

  @override
  void onDestroy(SceneContext owner) {
    if (_sprite != null) {
      _sprite!.removeFromParent();
      _sprite = null;
    }
  }

  @override
  void onSelected(SceneContext owner) {}

  @override
  void onDeselected(SceneContext owner) {}

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    if (oldComponent is IconComponent && oldComponent.iconName == iconName) {
      _sprite = oldComponent._sprite;
      oldComponent._sprite = null;
      if (_sprite != null && _sprite!.parent != owner.parent) {
        owner.parent.add(_sprite!);
      }
      return true;
    }
    return false;
  }

  @override
  void onUpdate(owner, double dt) {}

  @override
  GameComponent onReparent(GameObject self, GameObject? oldParent, GameObject? newParent, Map<String, GameObject> objectLookup) {
    return this;
  }
}
