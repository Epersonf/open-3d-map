import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_inspector.dart';
import 'package:open_3d_mapper/domain/general/vec3.dart';
import '../../../domain/scene/game_component.dart';
import '../../../domain/scene/game_object.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../domain/scene/scene_context.dart';
// Import do Gizmo Controller
import 'package:open_3d_mapper/components/inherited/transform/gizmo/gizmo_controller.dart';
import 'package:flutter/services.dart'; // For LogicalKeyboardKey
import 'package:open_3d_mapper/stores/selection_store.dart';

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
    // [CORREÇÃO CRÍTICA AQUI]
    // Recupera o ID do GameObject dono deste componente
    final myId = owner.parent.userData['gameObjectId'];
    final selected = SelectionStore.instance.selected;

    // Só atualizamos o Gizmo se ESTE for o objeto selecionado.
    // Isso impede que os filhos sobrescrevam a referência do Pai no GizmoController.
    if (selected != null && selected.id == myId) {
      GizmoController.instance.update(owner.parent);
    }

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
  GameComponent onReparent(
    GameObject self,
    GameObject? oldParent,
    GameObject? newParent,
    Map<String, GameObject> objectLookup,
  ) {
    // 1. Calcula a Matriz Global atual do objeto (baseada no pai antigo)
    final globalMatrix = _computeGlobalMatrix(self, oldParent, objectLookup);

    // 2/3. Calcula a Inversa da Matriz Global do novo pai e multiplica: NovaLocal = InversaNovoPai * GlobalAtual
    final newLocalMatrix = (newParent != null)
        ? (_computeGlobalMatrix(newParent, newParent.parentId != null ? objectLookup[newParent.parentId] : null, objectLookup)
              ..invert())
            .multiply(globalMatrix)
        : globalMatrix;

    // 4. Decompõe a matriz resultante em Posição, Rotação e Escala
    final newPos = three.Vector3();
    final newQuat = three.Quaternion();
    final newScale = three.Vector3();
    newLocalMatrix.decompose(newPos, newQuat, newScale);
    final newEuler = three.Euler().setFromQuaternion(newQuat);

    // 5. Retorna uma cópia do componente com os novos valores
    return copyWith(
      position: Vec3(x: newPos.x, y: newPos.y, z: newPos.z),
      rotation: Vec3(
        x: newEuler.x * (180 / 3.14159265359),
        y: newEuler.y * (180 / 3.14159265359),
        z: newEuler.z * (180 / 3.14159265359),
      ),
      scale: Vec3(x: newScale.x, y: newScale.y, z: newScale.z),
    );
  }

  /// Helper recursivo para calcular matriz global usando apenas dados puros
  three.Matrix4 _computeGlobalMatrix(
    GameObject obj,
    GameObject? parent,
    Map<String, GameObject> lookup,
  ) {
    final transform = obj.getComponent<TransformComponent>();
    final localMat = three.Matrix4();
    if (transform != null) {
      localMat.compose(
        three.Vector3(transform.position.x, transform.position.y, transform.position.z),
        three.Quaternion().setFromEuler(three.Euler(
          transform.rotation.x * (3.14159265359 / 180),
          transform.rotation.y * (3.14159265359 / 180),
          transform.rotation.z * (3.14159265359 / 180),
        )),
        three.Vector3(transform.scale.x, transform.scale.y, transform.scale.z),
      );
    }

    if (parent != null) {
      final grandParent = parent.parentId != null ? lookup[parent.parentId] : null;
      final parentGlobal = _computeGlobalMatrix(parent, grandParent, lookup);
      return parentGlobal.multiply(localMat);
    }

    return localMat;
  }

  @override
  void onSelected(SceneContext owner) {
    // Força atualização imediata ao selecionar, passando o objeto correto
    GizmoController.instance.update(owner.parent);
  }

  void _performFocus(SceneContext owner) {
    final camera = owner.camera;
    // Pega a posição global para focar corretamente mesmo se for filho
    final targetPos = three.Vector3();
    owner.parent.getWorldPosition(targetPos);

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
