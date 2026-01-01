import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class ProjectStore extends ChangeNotifier {
  ProjectStore._privateConstructor();
  static final ProjectStore instance = ProjectStore._privateConstructor();

  String? _projectPath;
  List<FileSystemEntity> _assets = [];

  String? get projectPath => _projectPath;
  List<FileSystemEntity> get assets => List.unmodifiable(_assets);

  void setProjectPath(String path) {
    _projectPath = path;
    refreshAssets();
    notifyListeners();
  }

  Future<void> refreshAssets() async {
    _assets = [];
    if (_projectPath == null) return;
    final assetsDir = Directory(p.join(_projectPath!, 'assets'));
    if (!await assetsDir.exists()) return;
    _assets = assetsDir.listSync(recursive: true);
    notifyListeners();
  }
}
