import 'package:flutter/material.dart';

/// Classe abstraite pour définir un objectif de niveau.
abstract class LevelGoal {
  /// Description affichée à l'utilisateur.
  String get description;

  /// Retourne true si l'objectif est atteint.
  bool get isCompleted;

  /// Appelé à chaque suppression d'icônes.
  /// [removedTypes] : liste des types de tuiles supprimées.
  void onIconsRemoved(List<dynamic> removedTypes);
}

/// Objectif : supprimer un certain nombre d'icônes d'un type donné.
class RemoveIconsGoal extends LevelGoal {
  final String iconType; // type de tuile (ex : 'timer_chip', 'firewall', etc.)
  final int targetCount;
  int _currentCount = 0;

  RemoveIconsGoal({required this.iconType, required this.targetCount});

  @override
  String get description =>
      'Remove $targetCount ${_iconName(iconType)}s ($progress/$targetCount)';

  int get progress => _currentCount;

  @override
  bool get isCompleted => _currentCount >= targetCount;

  @override
  void onIconsRemoved(List<dynamic> removedTypes) {
    _currentCount += removedTypes.where((type) => type == iconType).length;
  }

  String _iconName(String type) {
    switch (type) {
      case 'firewall':
        return 'firewall';
      case 'lock':
        return 'lock';
      case 'ai_chip':
        return 'AI chip';
      case 'bug':
        return 'bug';
      case 'warning':
        return 'warning';
      case 'save_disk':
        return 'save disk';
      case 'node_chain':
        return 'node chain';
      case 'timer_chip':
        return 'Timer Chip';
      default:
        return 'icon';
    }
  }
} 