import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:open_3d_mapper/domain/asset/asset.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../domain/project/project.dart';
import '../domain/scene/game_object.dart';
import '../domain/scene/transform.dart';
import '../domain/scene/scene.dart';

class ProjectStore extends ChangeNotifier {
  ProjectStore._privateConstructor();
  static final ProjectStore instance = ProjectStore._privateConstructor();
  String? _projectPath;
  String? _assetsRoot; // full path to project/assets
  String? _currentPath; // current directory being viewed (within assetsRoot)
  List<FileSystemEntity> _entries = [];

  String? get projectPath => _projectPath;
  String? get assetsRoot => _assetsRoot;
  String? get currentPath => _currentPath;
  List<FileSystemEntity> get entries => List.unmodifiable(_entries);
  Project? _project;
  Project? get project => _project;

  Map<String, dynamic>? get activeSceneMap {
    if (_project == null) return null;
    if (_project!.scenes.isEmpty) return null;
    // scenes are json_serializable Scene instances; Scene.rootObjects may be dynamic
    final first = _project!.scenes.first;
    // try to convert to Map via toJson
    return first.toJson();
  }

  void setProjectPath(String path) {
    _projectPath = path;
    _assetsRoot = p.join(path, 'assets');
    _currentPath = _assetsRoot;
    refreshCurrent();
    notifyListeners();
  }

  void setProject(Project project, String path) {
    _project = project;
    setProjectPath(path);
    notifyListeners();
  }

  Future<void> refreshCurrent() async {
    _entries = [];
    if (_currentPath == null) return;
    final dir = Directory(_currentPath!);
    if (!await dir.exists()) return;
    _entries = dir.listSync(recursive: false);
    _entries.sort((a, b) {
      // folders first then files, alphabetical
      final aIsDir = FileSystemEntity.isDirectorySync(a.path);
      final bIsDir = FileSystemEntity.isDirectorySync(b.path);
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    notifyListeners();
  }

  Future<void> cdInto(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      _currentPath = p.normalize(path);
      await refreshCurrent();
    }
  }

  Future<void> cdUp() async {
    if (_currentPath == null || _assetsRoot == null) return;
    final parent = p.dirname(_currentPath!);
    // prevent leaving the assets root
    final normParent = p.normalize(parent);
    final normRoot = p.normalize(_assetsRoot!);
    final normCurrent = p.normalize(_currentPath!);
    if (normParent == normRoot || normCurrent == normRoot) {
      // if already at root, do nothing
      if (normCurrent == normRoot) return;
      _currentPath = _assetsRoot;
      await refreshCurrent();
      return;
    }
    // ensure parent is still within assetsRoot
    if (p.isWithin(_assetsRoot!, parent) || normParent == normRoot) {
      _currentPath = parent;
      await refreshCurrent();
    }
  }

  Future<void> reload() async {
    await refreshCurrent();
  }

  /// Add an asset file (absolute path) as a GameObject into the active scene
  Future<void> addAssetAsGameObject(String absolutePath) async {
    if (_project == null || _projectPath == null) return;

    final rel = p.relative(absolutePath, from: _projectPath!);
    final base = p.basenameWithoutExtension(absolutePath);
    final goId = const Uuid().v4();

    // reuse existing asset if path already registered, otherwise create new with UUID
    String assetId;
    final existing = _project!.assets.where((a) => a.path == rel).toList();
    if (existing.isNotEmpty) {
      assetId = existing.first.id;
    } else {
      assetId = const Uuid().v4();
      final a = Asset(id: assetId, path: rel, type: p.extension(absolutePath).replaceFirst('.', ''));
      _project!.assets.add(a);
    }

    final go = GameObject(
      id: goId,
      name: base,
      parentId: null,
      assetId: assetId,
      transform: Transform(position: Vec3(x: 0, y: 0, z: 0), rotation: Vec3(x: 0, y: 0, z: 0), scale: Vec3(x: 1, y: 1, z: 1)),
    );

    // ensure project has at least one scene
    if (_project!.scenes.isEmpty) {
      final scene = Scene(id: 'scene-main', name: 'Main Scene', rootObjects: [go]);
      _project!.scenes.add(scene);
    } else {
      _project!.scenes.first.rootObjects.add(go);
    }

    // add asset entry if missing
    final exists = _project!.assets.any((a) => a.path == rel);
    if (!exists) {
      final a = Asset(id: base, path: rel, type: p.extension(absolutePath).replaceFirst('.', ''));
      _project!.assets.add(a);
    }

    notifyListeners();
  }

  Future<void> saveProject() async {
    if (_project == null || _projectPath == null) return;
    final indexFile = File(p.join(_projectPath!, 'index.json'));
    final encoded = const JsonEncoder.withIndent('  ').convert(_project!.toJson());
    await indexFile.writeAsString(encoded);
  }
}
