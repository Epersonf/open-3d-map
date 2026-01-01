import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

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

  void setProjectPath(String path) {
    _projectPath = path;
    _assetsRoot = p.join(path, 'assets');
    _currentPath = _assetsRoot;
    refreshCurrent();
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
}
