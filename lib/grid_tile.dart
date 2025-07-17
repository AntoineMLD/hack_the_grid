/// Classe de base pour une tuile de la grille.
/// Permet d'étendre facilement avec des tuiles spéciales (timer, effets, etc.).
abstract class GridTile {
  /// Chemin de l'asset à afficher pour cette tuile.
  String get assetPath;

  /// Type d'icône (pour l'objectif, la logique, etc.)
  String get type;

  /// Retourne true si la tuile est spéciale (timer, effet, etc.)
  bool get isSpecial => false;
}

/// Tuile spéciale : Timer Chip
/// Doit être supprimée avant expiration du timer, sinon malus.
class TimerChipTile extends GridTile {
  final int initialTimer;
  int timer;

  TimerChipTile({this.initialTimer = 5}) : timer = initialTimer;

  @override
  String get assetPath => 'assets/icons/Timer_Chip.png';

  @override
  String get type => 'timer_chip';

  @override
  bool get isSpecial => true;

  /// Décrémente le timer, retourne true si le timer a expiré.
  bool decrementTimer() {
    timer--;
    return timer <= 0;
  }
}

/// Exemple de tuile classique (pour usage futur, si besoin d'unifier la logique)
class BasicGridTile extends GridTile {
  final String assetPath;
  final String type;

  BasicGridTile({required this.assetPath, required this.type});
} 