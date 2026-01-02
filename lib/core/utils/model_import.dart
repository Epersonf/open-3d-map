import 'package:flutter_scene/scene.dart';

class ModelImport {
  static Map<String, Node> _modelCache = Map<String, Node>();

  static Future<Node> loadModel(String path) async {
    if (_modelCache.containsKey(path)) {
      return _modelCache[path]!.clone();
    }
    Node node = await Node.fromAsset(path);
    _modelCache[path] = node;
    return node.clone();
  }

  static void clearCache() {
    _modelCache.clear();
  }
}