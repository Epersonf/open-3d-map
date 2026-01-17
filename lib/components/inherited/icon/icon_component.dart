import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
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
  void onStart(dynamic owner) async {
    if (owner is! SceneContext) return;

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
  void onDestroy(dynamic owner) {
    if (_sprite != null) {
      _sprite!.removeFromParent();
      _sprite = null;
    }
  }
  // --- Lógica de Seleção Encapsulada ---

  @override
  void onSelected(dynamic owner) {
    if (_sprite is three.Sprite) {
      (_sprite as three.Sprite).material?.color = three.Color.fromHex32(0xFFAA00);
    }
  }

  @override
  void onDeselected(dynamic owner) {
    if (_sprite is three.Sprite) {
      (_sprite as three.Sprite).material?.color = three.Color.fromHex32(0xFFFFFF);
    }
  }

  @override
  void onUpdate(owner, double dt) {}
}
