import 'package:mobx/mobx.dart';
import '../domain/scene/game_object.dart';

class SelectionStore {
  SelectionStore._private();
  static final SelectionStore instance = SelectionStore._private();

  final Observable<GameObject?> _selected = Observable(null);

  GameObject? get selected => _selected.value;

  void select(GameObject? go) {
    Action(() => _selected.value = go)();
  }

  void clear() => select(null);
}
