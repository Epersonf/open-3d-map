import 'dart:io';

import 'dart:typed_data';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_importer/offline_import.dart';
import 'package:flutter_scene_importer/importer.dart';

class ModelImport {
  static Map<String, Node> _modelCache = Map<String, Node>();

  static Future<Node> loadModel(String absolutePath) async {
    if (_modelCache.containsKey(absolutePath)) {
      return _modelCache[absolutePath]!.clone();
    }
    final bytes = await File(absolutePath).readAsBytes();
    final byteData = ByteData.sublistView(bytes);
    final node = await Node.fromFlatbuffer(byteData);
    _modelCache[absolutePath] = node;
    return node.clone();
  }

  static void clearCache() {
    _modelCache.clear();
  }
}