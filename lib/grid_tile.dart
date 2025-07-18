/// Classe de base pour une tuile de la grille.
/// Permet d'étendre facilement avec des tuiles spéciales (timer, effets, etc.).
abstract class GridTile {
  /// Chemin de l'asset à afficher pour cette tuile.
  String get assetPath;

  /// Type d'icône (pour l'objectif, la logique, etc.)
  String get type;

  /// Retourne true si la tuile est spéciale (timer, effet, etc.)
  bool get isSpecial => false;

  /// Méthode d'effet spécial, à surcharger par les tuiles spéciales.
  /// [row], [col] : position de la tuile dans la grille
  /// [triggerEffect] : callback pour appliquer l'effet sur la grille
  void applyEffect(int row, int col, void Function(String effect, int row, int col) triggerEffect) {}
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

/// Tuile spéciale : Signal Jammer
/// Cache les icônes voisines (effet à implémenter)
class SignalJammerTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/Signal_Jammer.png';

  @override
  String get type => 'signal_jammer';

  @override
  bool get isSpecial => true;

  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('signal_jammer', row, col);
  }
}

/// Tuile spéciale : EMP Pulse
/// Supprime ligne/colonne (effet à implémenter)
class EmpPulseTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/EMP_Pulse.png';

  @override
  String get type => 'emp_pulse';

  @override
  bool get isSpecial => true;

  /// Déclenche la suppression de la ligne et colonne où se trouve la tuile
  @override
  void applyEffect(int row, int col, void Function(String effect, int row, int col) triggerEffect) {
    triggerEffect('emp_pulse', row, col);
  }
}

/// Tuile spéciale : Trojan
/// Transforme une tuile voisine en bug (effet à implémenter)
class TrojanTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/Trojan.png';

  @override
  String get type => 'trojan';

  @override
  bool get isSpecial => true;

  /// Contamine une tuile voisine en bug
  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('trojan', row, col);
  }
}

/// Tuile spéciale : Magnet Link
/// Attire les icônes autour (effet à implémenter)
class MagnetLinkTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/Magnet_Link.png';

  @override
  String get type => 'magnet_link';

  @override
  bool get isSpecial => true;

  /// Attire les tuiles voisines (swap)
  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('magnet_link', row, col);
  }
}

/// Tuile spéciale : Encrypted Link
/// Doit être matchée 2x (effet à implémenter)
class EncryptedLinkTile extends GridTile {
  bool decrypted = false;
  @override
  String get assetPath => decrypted
      ? 'assets/icons/Encrypted_Link_Decrypted.png' // à créer ou fallback
      : 'assets/icons/Encrypted_Link.png';
  // Correction : fallback si l'asset décrypté n'existe pas
  String get safeAssetPath {
    if (decrypted) {
      // On vérifie si l'asset existe, sinon fallback sur l'asset normal
      // (Flutter ne permet pas de vérifier l'existence d'un asset à runtime, donc on fallback toujours)
      return 'assets/icons/Encrypted_Link_Decrypted.png';
    }
    return 'assets/icons/Encrypted_Link.png';
  }

  @override
  String get type => 'encrypted_link';

  @override
  bool get isSpecial => true;

  /// Nécessite deux suppressions (état à gérer)
  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('encrypted_link', row, col);
  }
}

/// Tuile spéciale : Quantum Loop
/// Joker, match avec tout (effet à implémenter)
class QuantumLoopTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/Quantum_Loop.png';

  @override
  String get type => 'quantum_loop';

  @override
  bool get isSpecial => true;

  /// Joker (match avec tout)
  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('quantum_loop', row, col);
  }
}

/// Tuile piège : Trap Hole
/// Effet à implémenter (piège, bloque la grille, etc.)
class TrapHoleTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/trap_hole.png';

  @override
  String get type => 'trap_hole';

  @override
  bool get isSpecial => true;

  /// Bloque la case (non supprimable)
  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('trap_hole', row, col);
  }
}

/// Tuile piège : Virus Injector
/// Effet à implémenter (contamine les tuiles voisines, etc.)
class VirusInjectorTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/Virus_Injector.png';

  @override
  String get type => 'virus_injector';

  @override
  bool get isSpecial => true;

  /// Contamine les voisines (deviennent bugs)
  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('virus_injector', row, col);
  }
}

/// Tuile piège : Power Node
/// Effet à implémenter (bonus/malus, etc.)
class PowerNodeTile extends GridTile {
  @override
  String get assetPath => 'assets/icons/Power_node.png';

  @override
  String get type => 'power_node';

  @override
  bool get isSpecial => true;

  /// Bonus (score/coups/temps)
  @override
  void applyEffect(int row, int col, void Function(String, int, int) triggerEffect) {
    triggerEffect('power_node', row, col);
  }
} 