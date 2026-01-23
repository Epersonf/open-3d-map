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

  // --- MULTI-SCENE MANAGEMENT ---
  Scene? _currentScene;
  Scene? get currentScene => _currentScene;

  void setProjectPath(String path) {
    _projectPath = path;
    _assetsRoot = p.join(path, 'assets');
    _currentPath = _assetsRoot;
    refreshCurrent();
    notifyListeners();
  }

  /// Carrega o projeto e tenta carregar as cenas individuais da pasta 'scenes/'
  Future<void> setProject(Project project, String path,
      {String fileName = 'project.o3m'}) async {
    _project = project;
    _projectFileName = fileName;
    setProjectPath(path);

    // 1. Tentar carregar cenas da pasta 'scenes' para garantir dados mais recentes
    await _loadScenesFromDisk();

    // 2. Define a cena atual (a primeira ou cria uma se não houver)
    if (_project!.scenes.isNotEmpty) {
      _currentScene = _project!.scenes.first;
    } else {
      createScene(name: 'Main Scene');
    }

    notifyListeners();
  }

  Future<void> _loadScenesFromDisk() async {
    if (_project == null || _projectPath == null) return;

    final scenesDir = Directory(p.join(_projectPath!, 'scenes'));
    if (!await scenesDir.exists()) return;

    final List<Scene> loadedScenes = [];

    try {
      final files = scenesDir
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.json');

      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content);
          final scene = Scene.fromJson(json);
          loadedScenes.add(scene);
        } catch (e) {
          print('Error loading scene from ${file.path}: $e');
        }
      }
    } catch (e) {
      print('Error listing scenes dir: $e');
    }

    // Se carregamos cenas do disco, substituímos as que estão na memória do projeto
    // Isso permite que o arquivo project.o3m seja apenas um manifesto ou backup
    if (loadedScenes.isNotEmpty) {
      // Opcional: Manter a ordem ou mesclar. Aqui vamos substituir.
      _project!.scenes.clear();
      _project!.scenes.addAll(loadedScenes);
    }
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

  // --- SCENE OPERATIONS ---

  void selectScene(String sceneId) {
    if (_project == null) return;
    final scene = _project!.scenes.firstWhere((s) => s.id == sceneId,
        orElse: () => _project!.scenes.first);
    if (_currentScene != scene) {
      // Limpa seleção ao trocar de cena para evitar erros de referência
      SelectionStore.instance.clear();
      _currentScene = scene;
      notifyListeners();
    }
  }

  void createScene({String name = 'New Scene'}) {
    if (_project == null) return;
    final newScene = Scene(
        id: const Uuid().v4(),
        name: _generateUniqueSceneName(name),
        rootObjects: []);
    _project!.scenes.add(newScene);
    _currentScene = newScene;
    SelectionStore.instance.clear();
    notifyListeners();
  }

  void duplicateScene(String sceneId) {
    if (_project == null) return;
    try {
      final original = _project!.scenes.firstWhere((s) => s.id == sceneId);

      // Deep clone objects
      final clonedObjects = original.rootObjects
          .map((obj) => _deepCloneGameObject(obj, null,
                  isRootClone:
                      false) // false pois queremos manter nomes originais, só IDs novos
              )
          .toList();

      final clone = Scene(
          id: const Uuid().v4(),
          name: _generateUniqueSceneName("${original.name} Copy"),
          rootObjects: clonedObjects);

      _project!.scenes.add(clone);
      _currentScene = clone;
      SelectionStore.instance.clear();
      notifyListeners();
    } catch (_) {}
  }

  void deleteScene(String sceneId) {
    if (_project == null || _project!.scenes.length <= 1)
      return; // Prevent deleting last scene

    _project!.scenes.removeWhere((s) => s.id == sceneId);

    // Se deletou a cena atual, muda para a primeira disponível
    if (_currentScene?.id == sceneId) {
      _currentScene = _project!.scenes.first;
      SelectionStore.instance.clear();
    }
    notifyListeners();
  }

  void renameScene(String sceneId, String newName) {
    if (_project == null) return;
    final scene = _project!.scenes.firstWhere((s) => s.id == sceneId);
    scene.name = newName;
    notifyListeners();
  }

  String _generateUniqueSceneName(String baseName) {
    int count = 1;
    String name = baseName;
    while (_project!.scenes.any((s) => s.name == name)) {
      name = "$baseName $count";
      count++;
    }
    return name;
  }

  String _sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s\-]'), '') // Remove chars especiais
        .replaceAll(RegExp(r'\s+'), '_') // Espaços para _
        .toLowerCase();
  }

  // --- SAVE LOGIC ---

  Future<void> saveProject() async {
    if (_project == null || _projectPath == null) return;

    // 1. Salvar o arquivo principal do projeto (.o3m)
    final projectFile = File(p.join(_projectPath!, _projectFileName));
    final projectEncoded =
        const JsonEncoder.withIndent('  ').convert(_project!.toJson());
    await projectFile.writeAsString(projectEncoded);

    // 2. Salvar cada cena em um arquivo separado na pasta 'scenes'
    final scenesDir = Directory(p.join(_projectPath!, 'scenes'));
    if (!await scenesDir.exists()) {
      await scenesDir.create(recursive: true);
    }

    for (final scene in _project!.scenes) {
      final safeName = _sanitizeFilename(scene.name);
      // Fallback para ID se nome ficar vazio
      final filename = safeName.isEmpty ? scene.id : safeName;
      final sceneFile = File(p.join(scenesDir.path, '$filename.json'));

      final sceneEncoded =
          const JsonEncoder.withIndent('  ').convert(scene.toJson());
      await sceneFile.writeAsString(sceneEncoded);
    }
  }

  // --- OBJECT OPERATIONS (Updated to use _currentScene) ---

  Future<void> addAssetAsGameObject(String absolutePath) async {
    if (_project == null || _projectPath == null) return;

    // Ensure we have a scene
    if (_currentScene == null) {
      if (_project!.scenes.isEmpty)
        createScene();
      else
        _currentScene = _project!.scenes.first;
    }

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

    // Adiciona na cena atual
    _currentScene!.rootObjects.add(go);

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

    // Procura em todas as cenas para garantir consistência,
    // embora a UI só mostre a atual
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
    if (_project == null || _currentScene == null) return;

    final clone =
        _deepCloneGameObject(original, original.parentId, isRootClone: true);

    // Adiciona na cena onde o original está, ou na cena atual
    if (original.parentId == null) {
      // Se era root, clonamos na root da cena atual (simplificação)
      _currentScene!.rootObjects.add(clone);
    } else {
      final parent = findGameObjectById(original.parentId!);
      if (parent != null) {
        parent.children.add(clone);
      } else {
        _currentScene!.rootObjects.add(clone);
      }
    }

    SelectionStore.instance.select(clone);
    notifyListeners();
  }

  void createEmpty({String? parentId}) {
    if (_project == null) return;

    // Garante cena
    if (_currentScene == null) {
      if (_project!.scenes.isEmpty)
        createScene();
      else
        _currentScene = _project!.scenes.first;
    }

    final newObj = GameObject(
      id: const Uuid().v4(),
      name: 'Empty Object',
      parentId: parentId,
      components: [
        TransformComponent.defaultValue(),
        IconComponent(iconName: 'spawn')
      ],
    );

    if (parentId == null) {
      _currentScene!.rootObjects.add(newObj);
    } else {
      final parent = findGameObjectById(parentId);
      if (parent != null) {
        parent.children.add(newObj);
      } else {
        _currentScene!.rootObjects.add(newObj);
      }
    }

    notifyListeners();
  }

  void reparentObject(String childId, String? newParentId) {
    if (_project == null || _currentScene == null) return;
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
      // Move para a root da cena ATUAL
      _currentScene!.rootObjects.add(movedObj);
    } else {
      final parentInTree = findGameObjectById(newParentId);
      if (parentInTree != null) {
        parentInTree.children.add(movedObj);
      } else {
        // Fallback
        _currentScene!.rootObjects.add(movedObj);
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
