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

  String _projectFileName = 'project.o3m';
  List<FileSystemEntity> _entries = [];

  String? get projectPath => _projectPath;
  String? get assetsRoot => _assetsRoot;
  String? get currentPath => _currentPath;
  List<FileSystemEntity> get entries => List.unmodifiable(_entries);

  Project? _project;
  Project? get project => _project;

  Scene? _currentScene;
  Scene? get currentScene => _currentScene;

  void setProjectPath(String path) {
    _projectPath = path;
    _assetsRoot = p.join(path, 'assets');
    _currentPath = _assetsRoot;
    refreshCurrent();
    notifyListeners();
  }

  /// Define o projeto. Note que ignoramos as cenas que vierem dentro do JSON do projeto,
  /// pois a fonte da verdade agora é a pasta 'scenes/'.
  Future<void> setProject(Project project, String path,
      {String fileName = 'project.o3m'}) async {
    _project = project;
    _projectFileName = fileName;
    setProjectPath(path);

    // Limpa qualquer cena que possa ter vindo do JSON do manifesto (lixo ou cache antigo)
    _project!.scenes.clear();

    // Carrega as cenas diretamente do disco (Scan da pasta)
    await _loadScenesFromDisk();

    // Define a cena atual
    if (_project!.scenes.isNotEmpty) {
      // Opcional: Tentar manter a última cena aberta se salvarmos essa preferência
      _currentScene = _project!.scenes.first;
    } else {
      createScene(name: 'Main Scene');
    }

    notifyListeners();
  }

  /// Escaneia a pasta /scenes e popula o objeto Project
  Future<void> _loadScenesFromDisk() async {
    if (_project == null || _projectPath == null) return;

    final scenesDir = Directory(p.join(_projectPath!, 'scenes'));
    if (!await scenesDir.exists()) {
      await scenesDir.create(); // Garante que a pasta existe
      return;
    }

    final List<Scene> loadedScenes = [];

    try {
      final files = scenesDir
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.json');

      // Ordena por nome de arquivo para ter consistência na UI
      final sortedFiles = files.toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      for (final file in sortedFiles) {
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

    _project!.scenes.addAll(loadedScenes);
  }

  // --- ARQUIVOS E NAVEGAÇÃO ---

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

  Map<String, GameObject> _createObjectLookup() {
    final map = <String, GameObject>{};
    if (_project == null) return map;

    void traverse(List<GameObject> list) {
      for (final obj in list) {
        map[obj.id] = obj;
        traverse(obj.children);
      }
    }

    // Lookup global em todas as cenas carregadas
    for (final scene in _project!.scenes) {
      traverse(scene.rootObjects);
    }
    return map;
  }

  // --- OPERAÇÕES DE CENA ---

  void selectScene(String sceneId) {
    if (_project == null) return;
    final scene = _project!.scenes.firstWhere((s) => s.id == sceneId,
        orElse: () => _project!.scenes.first);
    if (_currentScene != scene) {
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
    
    // Salva imediatamente para criar o arquivo no disco
    saveProject(); 
    
    SelectionStore.instance.clear();
    notifyListeners();
  }

  void duplicateScene(String sceneId) {
    if (_project == null) return;
    try {
      final original = _project!.scenes.firstWhere((s) => s.id == sceneId);

      final clonedObjects = original.rootObjects
          .map((obj) => _deepCloneGameObject(obj, null, isRootClone: false))
          .toList();

      final clone = Scene(
          id: const Uuid().v4(),
          name: _generateUniqueSceneName("${original.name} Copy"),
          rootObjects: clonedObjects);

      _project!.scenes.add(clone);
      _currentScene = clone;
      
      saveProject(); // Persiste a nova cena

      SelectionStore.instance.clear();
      notifyListeners();
    } catch (_) {}
  }

  void deleteScene(String sceneId) {
    if (_project == null || _project!.scenes.length <= 1) return;

    final sceneToDelete = _project!.scenes.firstWhere((s) => s.id == sceneId);
    
    // Remove do disco
    if (_projectPath != null) {
        final safeName = _sanitizeFilename(sceneToDelete.name);
        final filename = safeName.isEmpty ? sceneToDelete.id : safeName;
        final file = File(p.join(_projectPath!, 'scenes', '$filename.json'));
        if (file.existsSync()) {
            try { file.deleteSync(); } catch (_) {}
        }
    }

    _project!.scenes.remove(sceneToDelete);

    if (_currentScene?.id == sceneId) {
      _currentScene = _project!.scenes.first;
      SelectionStore.instance.clear();
    }
    notifyListeners();
  }

  void renameScene(String sceneId, String newName) {
    if (_project == null) return;
    final scene = _project!.scenes.firstWhere((s) => s.id == sceneId);
    
    // Precisamos deletar o arquivo antigo se o nome mudar (pois o nome define o arquivo)
    // Ou manter ID como nome do arquivo para evitar isso. 
    // Na lógica atual (_sanitizeFilename), mudar nome muda arquivo.
    if (_projectPath != null) {
       final oldSafeName = _sanitizeFilename(scene.name);
       final oldFilename = oldSafeName.isEmpty ? scene.id : oldSafeName;
       final oldFile = File(p.join(_projectPath!, 'scenes', '$oldFilename.json'));
       if (oldFile.existsSync()) {
           try { oldFile.deleteSync(); } catch (_) {}
       }
    }

    scene.name = newName;
    saveProject(); // Salva para criar o arquivo com novo nome
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
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  // --- SAVE LOGIC (CORRIGIDO) ---

  Future<void> saveProject() async {
    if (_project == null || _projectPath == null) return;

    // 1. Salvar o arquivo project.o3m (MANIFESTO)
    // O truque: Criamos o JSON e forçamos 'scenes' a ser uma lista vazia.
    // Isso mantém o arquivo válido para o parser (que exige a chave), 
    // mas não salva dados duplicados.
    final projectFile = File(p.join(_projectPath!, _projectFileName));
    
    final projectJson = _project!.toJson();
    projectJson['scenes'] = []; // <--- AQUI ESTÁ A MÁGICA: Manifesto limpo.

    final projectEncoded =
        const JsonEncoder.withIndent('  ').convert(projectJson);
    await projectFile.writeAsString(projectEncoded);

    // 2. Salvar cada cena individualmente
    final scenesDir = Directory(p.join(_projectPath!, 'scenes'));
    if (!await scenesDir.exists()) {
      await scenesDir.create(recursive: true);
    }

    for (final scene in _project!.scenes) {
      final safeName = _sanitizeFilename(scene.name);
      final filename = safeName.isEmpty ? scene.id : safeName;
      final sceneFile = File(p.join(scenesDir.path, '$filename.json'));

      final sceneEncoded =
          const JsonEncoder.withIndent('  ').convert(scene.toJson());
      await sceneFile.writeAsString(sceneEncoded);
    }
  }

  // --- OBJECT OPERATIONS ---

  Future<void> addAssetAsGameObject(String absolutePath) async {
    if (_project == null || _projectPath == null) return;

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

    // Atualiza apenas na cena atual (performance e lógica correta)
    if (_currentScene != null) {
        replaced = _replaceInList(_currentScene!.rootObjects);
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

    if (_currentScene != null) {
        deleted = _removeInList(_currentScene!.rootObjects);
    }

    if (deleted && notify) {
      notifyListeners();
    }
    return deleted;
  }

  GameObject? findGameObjectById(String id) {
    if (_project == null) return null;

    // Busca apenas na cena atual
    if (_currentScene != null) {
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
        return findInList(_currentScene!.rootObjects);
    }
    return null;
  }

  void duplicateGameObject(GameObject original) {
    if (_project == null || _currentScene == null) return;

    final clone =
        _deepCloneGameObject(original, original.parentId, isRootClone: true);

    if (original.parentId == null) {
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

    final objectLookup = _createObjectLookup();
    final originalObj = objectLookup[childId];
    if (originalObj == null) return;

    final oldParent = originalObj.parentId != null
        ? objectLookup[originalObj.parentId]
        : null;
    final newParent = newParentId != null ? objectLookup[newParentId] : null;

    final newComponents = originalObj.components.map((comp) {
      return comp.onReparent(originalObj, oldParent, newParent, objectLookup);
    }).toList();

    final movedObj = GameObject(
      id: originalObj.id,
      name: originalObj.name,
      parentId: newParentId,
      components: newComponents,
      children: originalObj.children,
    );

    bool removed = deleteGameObject(childId, notify: false);
    if (!removed) return;

    if (newParentId == null) {
      _currentScene!.rootObjects.add(movedObj);
    } else {
      final parentInTree = findGameObjectById(newParentId);
      if (parentInTree != null) {
        parentInTree.children.add(movedObj);
      } else {
        _currentScene!.rootObjects.add(movedObj);
      }
    }

    notifyListeners();
  }

  GameObject _deepCloneGameObject(GameObject source, String? parentId,
      {bool isRootClone = false}) {
    final newId = const Uuid().v4();
    final newName = isRootClone ? '${source.name} (Clone)' : source.name;

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