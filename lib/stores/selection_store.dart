import 'package:mobx/mobx.dart';
import '../domain/scene/game_object/game_object.dart';

class SelectionStore {
  SelectionStore._private();
  static final SelectionStore instance = SelectionStore._private();

  // Observable que guarda o objeto selecionado
  final Observable<GameObject?> _selected = Observable(null);

  GameObject? get selected => _selected.value;

  void select(GameObject? go) {
    // runInAction garante que a mudança seja atômica e notifique os Observers
    runInAction(() {
      _selected.value = go;
    });
  }

  void clear() => select(null);
}
