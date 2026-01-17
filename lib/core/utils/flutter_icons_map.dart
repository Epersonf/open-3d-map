import 'package:flutter/material.dart';

/// Este mapa conecta a String 'nome' ao IconData real.
/// Isso elimina a necessidade de switch/case e permite busca dinâmica.
class FlutterIconsMap {
  static IconData fromName(String name) {
    return _icons[name] ?? Icons.help_outline; // Ícone padrão caso não ache
  }

  static List<String> get allNames => _icons.keys.toList();

  static Map<String, IconData> get map => _icons;

  // Lista curada com os ícones mais comuns para jogos/apps.
  // Você pode expandir isso infinitamente sem quebrar a lógica do componente.
  static const Map<String, IconData> _icons = {
    // Game Basics
    'spawn': Icons.flag,
    'player': Icons.person,
    'enemy': Icons.bug_report,
    'wall': Icons.crop_square,
    'light': Icons.lightbulb,
    'camera': Icons.videocam,
    'target': Icons.my_location,
    'sound': Icons.volume_up,
    'music': Icons.music_note,
    'settings': Icons.settings,

    // Objects & Items
    'key': Icons.vpn_key,
    'door': Icons.door_front_door,
    'chest': Icons.inbox,
    'coin': Icons.monetization_on,
    'gem': Icons.diamond,
    'heart': Icons.favorite,
    'potion': Icons.local_drink,
    'sword': Icons.gavel,
    'shield': Icons.shield,
    'book': Icons.menu_book,
    'map': Icons.map,

    // UI & Symbols
    'home': Icons.home,
    'search': Icons.search,
    'add': Icons.add,
    'check': Icons.check,
    'close': Icons.close,
    'delete': Icons.delete,
    'edit': Icons.edit,
    'save': Icons.save,
    'warning': Icons.warning,
    'error': Icons.error,
    'info': Icons.info,
    'help': Icons.help,
    'star': Icons.star,
    'lock': Icons.lock,
    'unlock': Icons.lock_open,
    'visible': Icons.visibility,
    'hidden': Icons.visibility_off,
    'cloud': Icons.cloud,
    'flash': Icons.flash_on,
    'time': Icons.access_time,
  };
}
