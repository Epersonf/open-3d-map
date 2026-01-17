import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:open_3d_mapper/domain/scene/game_object/game_object.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../domain/scene/game_component.dart';
import '../../../domain/scene/scene_context.dart';
import '../../../domain/asset/asset.dart';
import 'mesh_inspector.dart';

part 'mesh_component.g.dart';

@JsonSerializable()
class MeshComponent implements GameComponent {
  static const String typeId = 'mesh';

  @override
  String get id => typeId;

  final String? assetId;
  final bool visibleInRuntime;

  // --- Runtime Cache ---
  // Apenas guardamos o objeto 3D. Removemos o cache de materiais
  // para evitar referências mortas.
  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Object3D? _meshObject;

  MeshComponent({this.assetId, this.visibleInRuntime = true});

  factory MeshComponent.fromJson(Map<String, dynamic> json) =>
      _$MeshComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MeshComponentToJson(this);

  @override
  MeshComponent copyWith({String? assetId, bool? visibleInRuntime}) {
    return MeshComponent(
      assetId: assetId ?? this.assetId,
      visibleInRuntime: visibleInRuntime ?? this.visibleInRuntime,
    );
  }

  @override
  Widget inspectorWidget() => const MeshInspector();

  @override
  void onStart(dynamic owner) async {
    // 1. Hot Reload Manual
    if (_meshObject != null) {
      if (_meshObject!.parent != owner.parent) {
        owner.parent.add(_meshObject!);
      }
      return;
    }

    if (owner is! SceneContext || assetId == null) return;

    final project = owner.projectStore.project;
    final rootPath = owner.projectStore.projectPath;
    if (project == null || rootPath == null) return;

    final asset = project.assets.firstWhere(
      (a) => a.id == assetId,
      orElse: () => Asset(id: '', path: '', type: ''),
    );

    if (asset.path.isEmpty) return;

    final model =
        await owner.modelManager.loadModel(assetId!, rootPath, asset.path);

    if (model != null) {
      _meshObject = model.clone(true);
      _applyProperties();
      owner.parent.add(_meshObject!);
    }
  }

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    if (oldComponent is MeshComponent && oldComponent.assetId == assetId) {
      _meshObject = oldComponent._meshObject;

      oldComponent._meshObject = null;

      _applyProperties();

      return true;
    }
    return false;
  }

  void _applyProperties() {
    if (_meshObject != null) {
      _meshObject!.visible = visibleInRuntime;
    }
  }

  @override
  void onDestroy(SceneContext owner) {
    if (_meshObject != null) {
      _meshObject!.removeFromParent();
      _meshObject = null;
    }
  }

  @override
  void onSelected(SceneContext owner) {}

  @override
  void onDeselected(SceneContext owner) {}

  @override
  void onUpdate(owner, double dt) {}

  @override
  GameComponent onReparent(GameObject self, GameObject? oldParent, GameObject? newParent, Map<String, GameObject> objectLookup) {
    return this;
  }
}
