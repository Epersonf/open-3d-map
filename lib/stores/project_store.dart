import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/components/inherited/mesh/mesh_component.dart';
import 'package:open_3d_mapper/components/inherited/icon/icon_component.dart';
import 'package:open_3d_mapper/domain/asset/asset.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../domain/project/project.dart';
import '../domain/scene/game_object/game_object.dart';
import '../domain/scene/scene.dart';
import '../stores/selection_store.dart';

class ProjectStore extends ChangeNotifier {
  ProjectStore._privateConstructor();
  static final ProjectStore instance = ProjectStore._privateConstructor();
  String? _projectPath;
  String? _assetsRoot;
  String? _currentPath;
  // Nome do arquivo do projeto (ex: 'project.o3m' ou personalizado)
  String _projectFileName = 'project.o3m';
  List<FileSystemEntity> _entries = [];

  String? get projectPath => _projectPath;
  String? get assetsRoot => _assetsRoot;
  String? get currentPath => _currentPath;
  List<FileSystemEntity> get entries => List.unmodifiable(_entries);
  Project? _project;
  Project? get project => _project;

  void setProjectPath(String path) {
    _projectPath = path;
    _assetsRoot = p.join(path, 'assets');
    _currentPath = _assetsRoot;
    refreshCurrent();
    notifyListeners();
  }

  // Modificado para receber opcionalmente o nome do arquivo do projeto
  void setProject(Project project, String path,
      {String fileName = 'project.o3m'}) {
    _project = project;
    _projectFileName = fileName;

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
    final normParent = p.normalize(parent);
    final normRoot = p.normalize(_assetsRoot!);
    final normCurrent = p.normalize(_currentPath!);
    if (normParent == normRoot || normCurrent == normRoot) {
      if (normCurrent == normRoot) return;
      _currentPath = _assetsRoot;
      await refreshCurrent();
      return;
    }
    if (p.isWithin(_assetsRoot!, parent) || normParent == normRoot) {
      _currentPath = parent;
      await refreshCurrent();
    }
  }

  Future<void> reload() async {
    await refreshCurrent();
  }

  /// Create a lookup map of id->GameObject for the whole project
  Map<String, GameObject> _createObjectLookup() {
    final map = <String, GameObject>{};
    if (_project == null) return map;

    void traverse(List<GameObject> list) {
      for (final obj in list) {
        map[obj.id] = obj;
        traverse(obj.children);
      }
    }

    for (final scene in _project!.scenes) {
      traverse(scene.rootObjects);
    }
    return map;
  }

  Future<void> addAssetAsGameObject(String absolutePath) async {
    if (_project == null || _projectPath == null) return;

    final rel = p.relative(absolutePath, from: _projectPath!);
    final base = p.basenameWithoutExtension(absolutePath);
    final goId = const Uuid().v4();

    String assetId;
    final existing = _project!.assets.where((a) => a.path == rel).toList();
    if (existing.isNotEmpty) {
      assetId = existing.first.id;
    } else {
      assetId = const Uuid().v4();
      final a = Asset(
          id: assetId,
          path: rel,
          type: p.extension(absolutePath).replaceFirst('.', ''));
      _project!.assets.add(a);
    }

    final mesh = MeshComponent(assetId: assetId, visibleInRuntime: true);
    final transformComp = TransformComponent.defaultValue();

    final go = GameObject(
      id: goId,
      name: base,
      parentId: null,
      components: [transformComp, mesh],
    );

    if (_project!.scenes.isEmpty) {
      final scene =
          Scene(id: 'scene-main', name: 'Main Scene', rootObjects: [go]);
      _project!.scenes.add(scene);
    } else {
      _project!.scenes.first.rootObjects.add(go);
    }

    final exists = _project!.assets.any((a) => a.path == rel);
    if (!exists) {
      final a = Asset(
          id: base,
          path: rel,
          type: p.extension(absolutePath).replaceFirst('.', ''));
      _project!.assets.add(a);
    }

    notifyListeners();
  }

  // Modificado para salvar usando o nome do arquivo do projeto e extensão .o3m
  Future<void> saveProject() async {
    if (_project == null || _projectPath == null) return;
    final file = File(p.join(_projectPath!, _projectFileName));
    final encoded =
        const JsonEncoder.withIndent('  ').convert(_project!.toJson());
    await file.writeAsString(encoded);
  }

  bool updateGameObject(GameObject updated) {
    if (_project == null) return false;
    bool replaced = false;

    bool _replaceInList(List<GameObject> list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].id == updated.id) {
          list[i] = updated;
          return true;
        }
        if (list[i].children.isNotEmpty) {
          if (_replaceInList(list[i].children)) return true;
        }
      }
      return false;
    }

    for (final scene in _project!.scenes) {
      if (_replaceInList(scene.rootObjects)) {
        replaced = true;
        break;
      }
    }

    if (replaced) notifyListeners();
    return replaced;
  }

  bool deleteGameObject(String id, {bool notify = true}) {
    if (_project == null) return false;
    bool deleted = false;

    bool _removeInList(List<GameObject> list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].id == id) {
          list.removeAt(i);
          return true;
        }
        if (list[i].children.isNotEmpty) {
          if (_removeInList(list[i].children)) return true;
        }
      }
      return false;
    }

    for (final scene in _project!.scenes) {
      if (_removeInList(scene.rootObjects)) {
        deleted = true;
        break;
      }
    }

    if (deleted && notify) {
      notifyListeners();
    }
    return deleted;
  }

  GameObject? findGameObjectById(String id) {
    if (_project == null) return null;

    for (final scene in _project!.scenes) {
      GameObject? findInList(List<GameObject> list) {
        for (final obj in list) {
          if (obj.id == id) return obj;
          if (obj.children.isNotEmpty) {
            final found = findInList(obj.children);
            if (found != null) return found;
          }
        }
        return null;
      }

      final found = findInList(scene.rootObjects);
      if (found != null) return found;
    }
    return null;
  }

  void duplicateGameObject(GameObject original) {
    if (_project == null || _project!.scenes.isEmpty) return;

    final clone =
        _deepCloneGameObject(original, original.parentId, isRootClone: true);
    final scene = _project!.scenes.first;

    if (original.parentId == null) {
      scene.rootObjects.add(clone);
    } else {
      final parent = findGameObjectById(original.parentId!);
      if (parent != null) {
        parent.children.add(clone);
      } else {
        scene.rootObjects.add(clone);
      }
    }

    SelectionStore.instance.select(clone);
    notifyListeners();
  }

  void createEmpty({String? parentId}) {
    if (_project == null) return;

    final newObj = GameObject(
      id: const Uuid().v4(),
      name: 'Empty Object',
      parentId: parentId,
      components: [
        TransformComponent.defaultValue(),
        IconComponent(iconName: 'spawn')
      ],
    );

    if (_project!.scenes.isEmpty) {
      final scene =
          Scene(id: 'scene-main', name: 'Main Scene', rootObjects: [newObj]);
      _project!.scenes.add(scene);
    } else {
      if (parentId == null) {
        _project!.scenes.first.rootObjects.add(newObj);
      } else {
        final parent = findGameObjectById(parentId);
        if (parent != null) {
          parent.children.add(newObj);
        } else {
          _project!.scenes.first.rootObjects.add(newObj);
        }
      }
    }
    notifyListeners();
  }

  void reparentObject(String childId, String? newParentId) {
    if (_project == null) return;
    if (childId == newParentId) return;

    // 1. Validar descendência
    if (newParentId != null) {
      final child = findGameObjectById(childId);
      if (child != null) {
        bool _isDescendant(GameObject node, String idToFind) {
          for (final c in node.children) {
            if (c.id == idToFind) return true;
            if (_isDescendant(c, idToFind)) return true;
          }
          return false;
        }

        if (_isDescendant(child, newParentId)) return;
      }
    }

    // 2. Preparar lookup e encontrar objetos
    final objectLookup = _createObjectLookup();
    final originalObj = objectLookup[childId];
    if (originalObj == null) return;

    final oldParent = originalObj.parentId != null
        ? objectLookup[originalObj.parentId]
        : null;
    final newParent = newParentId != null ? objectLookup[newParentId] : null;

    // 3. Processar componentes para permitir que cada um ajuste seus dados
    final newComponents = originalObj.components.map((comp) {
      return comp.onReparent(originalObj, oldParent, newParent, objectLookup);
    }).toList();

    // 4. Criar o objeto atualizado com novos componentes
    final movedObj = GameObject(
      id: originalObj.id,
      name: originalObj.name,
      parentId: newParentId,
      components: newComponents,
      children: originalObj.children,
    );

    // 5. Remover da árvore antiga e adicionar na nova
    bool removed = deleteGameObject(childId, notify: false);
    if (!removed) return;

    if (newParentId == null) {
      _project!.scenes.first.rootObjects.add(movedObj);
    } else {
      final parentInTree = findGameObjectById(newParentId);
      if (parentInTree != null) {
        parentInTree.children.add(movedObj);
      } else {
        _project!.scenes.first.rootObjects.add(movedObj);
      }
    }

    notifyListeners();
  }

  GameObject _deepCloneGameObject(GameObject source, String? parentId,
      {bool isRootClone = false}) {
    final newId = const Uuid().v4();
    final newName = isRootClone ? '${source.name} (Clone)' : source.name;

    // Clone components via their copyWith
    final newComponents = source.components.map((c) => c.copyWith()).toList();

    return GameObject(
      id: newId,
      name: newName,
      parentId: parentId,
      components: newComponents,
      children: source.children
          .map((child) => _deepCloneGameObject(child, newId))
          .toList(),
    );
  }
}
