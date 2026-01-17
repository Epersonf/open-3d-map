import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Object3D? _meshObject;

  MeshComponent({this.assetId, this.visibleInRuntime = true});

  factory MeshComponent.fromJson(Map<String, dynamic> json) => _$MeshComponentFromJson(json);

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
    if (owner is! SceneContext || assetId == null) return;

    final project = owner.projectStore.project;
    final rootPath = owner.projectStore.projectPath;
    if (project == null || rootPath == null) return;

    final asset = project.assets.firstWhere(
      (a) => a.id == assetId,
      orElse: () => Asset(id: '', path: '', type: ''),
    );

    if (asset.path.isEmpty) return;

    final model = await owner.modelManager.loadModel(assetId!, rootPath, asset.path);
    if (model != null) {
      _meshObject = model.clone();
      _meshObject!.visible = visibleInRuntime;
      owner.parent.add(_meshObject!);
    }
  }

  @override
  void onDestroy(dynamic owner) {
    if (_meshObject != null) {
      _meshObject!.removeFromParent();
      _meshObject = null;
    }
  }
  // --- Lógica de Seleção Encapsulada ---

  @override
  void onSelected(dynamic owner) {
    if (_meshObject == null) return;
    _setHighlight(true);
  }

  @override
  void onDeselected(dynamic owner) {
    if (_meshObject == null) return;
    _setHighlight(false);
  }

  void _setHighlight(bool active) {
    _meshObject!.traverse((object) {
      if (object is three.Mesh && object.material is three.MeshStandardMaterial) {
        final material = object.material as three.MeshStandardMaterial;
        if (active) {
          material.emissive = three.Color.fromHex32(0x444400);
          material.emissiveIntensity = 0.5;
        } else {
          material.emissive = three.Color.fromHex32(0x000000);
          material.emissiveIntensity = 0.0;
        }
      }
    });
  }

  @override
  void onUpdate(owner, double dt) {}
}
