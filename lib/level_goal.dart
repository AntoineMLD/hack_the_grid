import 'package:flutter/material.dart';

/// Classe abstraite pour définir un objectif de niveau.
abstract class LevelGoal {
  /// Description affichée à l'utilisateur.
  String get description;

  /// Retourne true si l'objectif est atteint.
  bool get isCompleted;

  /// Appelé à chaque suppression d'icônes.
  /// [removedIcons] : liste des indices d'icônes supprimées.
  void onIconsRemoved(List<int> removedIcons);
}

/// Objectif : supprimer un certain nombre d'icônes d'un type donné.
class RemoveIconsGoal extends LevelGoal {
  final int iconIndex; // index dans la liste des assets
  final int targetCount;
  int _currentCount = 0;

  RemoveIconsGoal({required this.iconIndex, required this.targetCount});

  @override
  String get description =>
      'Remove $targetCount ${_iconName(iconIndex)}s ($progress/$targetCount)';

  int get progress => _currentCount;

  @override
  bool get isCompleted => _currentCount >= targetCount;

  @override
  void onIconsRemoved(List<int> removedIcons) {
    _currentCount += removedIcons.where((idx) => idx == iconIndex).length;
  }

  String _iconName(int idx) {
    // À adapter si tu veux des noms plus jolis ou localisés
    switch (idx) {
      case 1:
        return 'firewall';
      case 0:
        return 'lock';
      case 2:
        return 'AI chip';
      case 3:
        return 'bug';
      case 4:
        return 'warning';
      case 5:
        return 'save disk';
      case 6:
        return 'node chain';
      default:
        return 'icon';
    }
  }
} 