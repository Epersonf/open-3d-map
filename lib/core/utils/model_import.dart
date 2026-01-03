import 'package:three_js/three_js.dart' as three;

class ModelImport {
  static Future<three.Object3D?> loadModel(String filePath) async {
    final extension = filePath.toLowerCase().split('.').last;
    
    try {
      if (extension == 'glb' || extension == 'gltf') {
        final loader = three.GLTFLoader();
        final gltf = await loader.fromPath(filePath);
        return gltf?.scene;
      } else if (extension == 'fbx') {
        final loader = three.FBXLoader();
        return await loader.fromPath(filePath);
      } else if (extension == 'obj') {
        final loader = three.OBJLoader();
        return await loader.fromPath(filePath);
      }
    } catch (e) {
      print('Error loading model $filePath: $e');
    }
    
    return null;
  }
}