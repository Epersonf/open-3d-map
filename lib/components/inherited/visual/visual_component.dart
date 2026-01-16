import 'package:json_annotation/json_annotation.dart';
import '../../../domain/scene/game_component.dart';

part 'visual_component.g.dart';

enum VisualType {
  mesh,
  icon,
  none,
}

@JsonSerializable()
class VisualComponent implements GameComponent {
  // Identificador estático para registro
  static const String typeId = 'visual';

  @override
  String get id => typeId;

  final VisualType type;
  final String? assetId;
  final String? iconName;
  final bool visibleInRuntime;

  VisualComponent({
    this.type = VisualType.none,
    this.assetId,
    this.iconName,
    this.visibleInRuntime = true,
  });

  factory VisualComponent.fromJson(Map<String, dynamic> json) => _$VisualComponentFromJson(json);
  Map<String, dynamic> toJson() => _$VisualComponentToJson(this);

  VisualComponent copyWith({
    VisualType? type,
    String? assetId,
    String? iconName,
    bool? visibleInRuntime,
  }) {
    return VisualComponent(
      type: type ?? this.type,
      assetId: assetId ?? this.assetId,
      iconName: iconName ?? this.iconName,
      visibleInRuntime: visibleInRuntime ?? this.visibleInRuntime,
    );
  }
  
  @override
  void onDestroy(owner) {}
  
  @override
  void onStart(owner) {}
  
  @override
  void onUpdate(owner, double dt) {}
  
  
}
