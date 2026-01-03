import '../../domain/scene/game_object.dart';

class SceneUtils {
  /// Encontra um GameObject pelo ID na lista de objetos
  static GameObject? findGameObjectById(List<GameObject> objects, String id) {
    for (final obj in objects) {
      if (obj.id == id) {
        return obj;
      }

      if (obj.children.isNotEmpty) {
        final found = findGameObjectById(obj.children, id);
        if (found != null) {
          return found;
        }
      }
    }

    return null;
  }

  /// Encontra um GameObject pelo ID no projeto (a partir de uma raiz)
  static GameObject? findGameObjectInProject(GameObject? root, String id) {
    if (root == null) return null;

    if (root.id == id) {
      return root;
    }

    for (final child in root.children) {
      final found = findGameObjectInProject(child, id);
      if (found != null) {
        return found;
      }
    }

    return null;
  }

  /// Encontra o caminho para um GameObject na hierarquia
  static List<GameObject> findPathToGameObject(GameObject root, String targetId) {
    final path = <GameObject>[];

    bool _findPath(GameObject current, List<GameObject> currentPath) {
      currentPath.add(current);

      if (current.id == targetId) {
        path.addAll(currentPath);
        return true;
      }

      for (final child in current.children) {
        if (_findPath(child, List.from(currentPath))) {
          return true;
        }
      }

      return false;
    }

    _findPath(root, []);
    return path;
  }
}
