import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_inspector.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import '../../../domain/scene/game_component.dart';
import '../../../domain/scene/scene_context.dart';
// Import do Gizmo Controller
import 'package:open_3d_mapper/components/inherited/transform/gizmo/gizmo_controller.dart';
import 'package:flutter/services.dart'; // For LogicalKeyboardKey
import 'package:open_3d_mapper/stores/selection_store.dart';
import 'package:three_js/three_js.dart' as three;

part 'transform_component.g.dart';

@JsonSerializable(explicitToJson: true)
class TransformComponent extends GameComponent {
  static const String typeId = 'transform';

  @override
  String get id => typeId;

  
  final Vec3 position;
  final Vec3 rotation;
  final Vec3 scale;

  TransformComponent({
    required this.position,
    required this.rotation,
    required this.scale,
  });

  factory TransformComponent.defaultValue() {
    return TransformComponent(
      position: Vec3(x: 0, y: 0, z: 0),
      rotation: Vec3(x: 0, y: 0, z: 0),
      scale: Vec3(x: 1, y: 1, z: 1),
    );
  }

  factory TransformComponent.fromJson(Map<String, dynamic> json) => _$TransformComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TransformComponentToJson(this);

  @override
  TransformComponent copyWith({
    Vec3? position,
    Vec3? rotation,
    Vec3? scale,
  }) {
    return TransformComponent(
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }

  @override
  void onStart(SceneContext owner) {
    _applyTransform(owner);
    // Configura o GizmoController com a cena e câmera atuais
    GizmoController.instance.setup(owner.scene, owner.camera);
  }

  @override
  void onUpdate(SceneContext owner, double dt) {
    _applyTransform(owner);
    GizmoController.instance.update();

    // --- Polling input for focus action (F) ---
    try {
      if (owner.input.isKeyDown(LogicalKeyboardKey.keyF)) {
        final selected = SelectionStore.instance.selected;
        // Recupera o ID deste objeto através do userData do Object3D pai
        final myId = owner.parent.userData['gameObjectId'];

        // Compara ID com ID (seguro contra recriação de instâncias no Store)
        if (selected != null && selected.id == myId) {
          _performFocus(owner);
        }
      }
    } catch (_) {}
  }

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    _applyTransform(owner);
    return true;
  }

  void _applyTransform(SceneContext owner) {
    final object3d = owner.parent;

    object3d.position.setValues(position.x, position.y, position.z);

    const deg2rad = 3.14159265359 / 180.0;
    object3d.rotation.set(
      rotation.x * deg2rad,
      rotation.y * deg2rad,
      rotation.z * deg2rad,
    );

    object3d.scale.setValues(scale.x, scale.y, scale.z);
  }

  @override
  Widget inspectorWidget() {
    return TransformInspector();
  }

  @override
  void onSelected(SceneContext owner) {
    GizmoController.instance.update();
  }

  void _performFocus(SceneContext owner) {
    final camera = owner.camera;
    final targetPos = three.Vector3(position.x, position.y, position.z);

    const double distance = 5.0;
    final offset = three.Vector3(0, 2, distance);

    camera.position.setValues(
      targetPos.x + offset.x,
      targetPos.y + offset.y,
      targetPos.z + offset.z,
    );
    camera.lookAt(targetPos);
  }
}
