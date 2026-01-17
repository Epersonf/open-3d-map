import 'package:flutter/material.dart';
import 'package:open_3d_mapper/domain/scene/game_object/game_object.dart';
import 'package:open_3d_mapper/domain/scene/scene_context.dart';

abstract class GameComponent {
  String get id;

  Map<String, dynamic> toJson();

  GameComponent copyWith();

  void onStart(SceneContext owner) {}

  void onUpdate(SceneContext owner, double dt) {}

  void onDestroy(SceneContext owner) {}

  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) => false;

  void onSelected(SceneContext owner) {}

  void onDeselected(SceneContext owner) {}

  GameComponent onReparent(
    GameObject self,
    GameObject? oldParent,
    GameObject? newParent,
    Map<String, GameObject> objectLookup,
  ) {
    return this;
  }

  Widget inspectorWidget() {
    return Text('No inspector for $id');
  }
}
