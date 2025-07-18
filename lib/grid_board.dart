import 'dart:math';
import 'package:flutter/material.dart';
import 'level_goal.dart';
import 'cyber_tile.dart';
import 'level.dart';
import 'grid_tile.dart' as custom;
import 'dart:async';

/// Widget principal de la grille de jeu Hack The Grid.
/// Gère l'état de la grille, la sélection, la suppression et le remplissage.
class GridBoard extends StatefulWidget {
  const GridBoard({super.key});

  static const int gridSize = 6;
  static const List<String> iconAssets = [
    'assets/icons/icon_lock_clean.png',
    'assets/icons/icon_firewall_clean.png',
    'assets/icons/icon_ai_chip_clean.png',
    'assets/icons/icon_bug_clean.png',
    'assets/icons/icon_warning_clean.png',
    'assets/icons/icon_save_disk_clean.png',
    'assets/icons/icon_node_chain_clean.png',
  ];

  @override
  State<GridBoard> createState() => _GridBoardState();
}

class _PendingAnimation {
  final Offset pos;
  final String assetPath;
  _PendingAnimation(this.pos, this.assetPath);
}

class VictoryDialog extends StatelessWidget {
  final VoidCallback onNext;
  const VictoryDialog({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.tealAccent, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.tealAccent.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, color: Colors.tealAccent, size: 64),
            const SizedBox(height: 24),
            const Text(
              'HACK SUCCESSFUL',
              style: TextStyle(
                fontSize: 32,
                color: Colors.tealAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mission completed!\nYou can proceed to the next challenge.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
              ),
              onPressed: onNext,
              child: const Text('NEXT MISSION'),
            ),
          ],
        ),
      ),
    );
  }
}

class GameOverDialog extends StatelessWidget {
  final VoidCallback onRetry;
  const GameOverDialog({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            const Text(
              'ACCESS DENIED',
              style: TextStyle(
                fontSize: 32,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hack failed!\nTry again to continue your mission.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
              ),
              onPressed: onRetry,
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridBoardState extends State<GridBoard> {
  late List<List<custom.GridTile?>> grid; // Grille d'objets GridTile ou null
  List<Offset> selected = [];
  int score = 0;
  int movesLeft = 20;
  late LevelGoal goal;
  bool isDragging = false;
  GlobalKey gridKey = GlobalKey();
  final List<_PendingAnimation> _pendingAnimations = [];
  int currentLevel = 0;
  late Level level;

  // Ajout : gestion dynamique des niveaux
  List<Level> levels = [];
  bool isLoading = true;
  String? loadingError;

  // Stocke le dernier type d'icône supprimé pour chaque position animée
  final Map<Offset, int> _lastRemovedIconIdx = {};

  int? _lastRemovedIconIdxFor(Offset pos) => _lastRemovedIconIdx[pos];

  Timer? _timer;
  int _timeLeft = 0;

  Set<Offset> _hiddenTiles = {};
  Set<String> _discoveredSpecials = {};
  String? _pendingSpecialToShow;
  Set<Offset> _magnetizedTiles = {};
  Set<Offset> _empPulseHighlight = {};

  static const Map<String, Map<String, String>> specialTileInfo = {
    'emp_pulse': {
      'title': 'EMP Pulse Overload',
      'desc': 'Removes the entire row and column when matched.',
      'asset': 'assets/icons/EMP_Pulse.png',
    },
    'trojan': {
      'title': 'Trojan Infiltration',
      'desc': 'Transforms a random adjacent tile into a bug when matched.',
      'asset': 'assets/icons/Trojan.png',
    },
    'magnet_link': {
      'title': 'Magnetized Network',
      'desc': 'Pulls all adjacent tiles into the center position.',
      'asset': 'assets/icons/Magnet_Link.png',
    },
    'signal_jammer': {
      'title': 'Signal Jammer Breach',
      'desc': 'Hides all adjacent tiles until you make your next move.',
      'asset': 'assets/icons/Signal_Jammer.png',
    },
    'encrypted_link': {
      'title': 'Encrypted Data Crack',
      'desc': 'Must be matched twice: first to decrypt, then to remove.',
      'asset': 'assets/icons/Encrypted_Link.png',
    },
    'quantum_loop': {
      'title': 'Quantum Loop Anomaly',
      'desc': 'Wildcard: can be matched with any tile type.',
      'asset': 'assets/icons/Quantum_Loop.png',
    },
    'timer_chip': {
      'title': 'Time Bomb Defusal',
      'desc': 'Must be removed before the timer runs out.',
      'asset': 'assets/icons/Timer_Chip.png',
    },
    'trap_hole': {
      'title': 'Trap Hole',
      'desc': 'Blocks the cell. Cannot be removed.',
      'asset': 'assets/icons/trap_hole.png',
    },
    'virus_injector': {
      'title': 'Virus Injector',
      'desc': 'Turns all adjacent tiles into bugs.',
      'asset': 'assets/icons/Virus_Injector.png',
    },
    'power_node': {
      'title': 'Power Node',
      'desc': 'Bonus: +5 moves or +10 seconds.',
      'asset': 'assets/icons/Power_node.png',
    },
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  /// Charge dynamiquement la liste des niveaux depuis le CSV
  Future<void> _loadLevels() async {
    setState(() {
      isLoading = true;
      loadingError = null;
    });
    try {
      levels = await getLevels();
      if (levels.isEmpty) {
        setState(() {
          loadingError = 'Aucun niveau trouvé.';
          isLoading = false;
        });
        return;
      }
      _loadLevel(0);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        loadingError = 'Erreur de chargement des niveaux :\n$e';
        isLoading = false;
      });
    }
  }

  void _loadLevel(int idx) {
    _timer?.cancel();
    setState(() {
      _hiddenTiles.clear(); // Vider les tuiles cachées par Signal Jammer
      _magnetizedTiles.clear(); // Vider les tuiles surlignées Magnet Link
      _empPulseHighlight.clear(); // Vider l'effet EMP Pulse
      currentLevel = idx % levels.length;
      level = levels[currentLevel];
      goal = level.goal is RemoveIconsGoal
          ? RemoveIconsGoal(
              iconType: (level.goal as RemoveIconsGoal).iconType,
              targetCount: (level.goal as RemoveIconsGoal).targetCount,
            )
          : level.goal;
      movesLeft = level.moves;
      score = 0;
      _generateGrid();
      // Timer pour les niveaux à temps limité
      if (goal is TimedRemoveIconsGoal) {
        _timeLeft = (goal as TimedRemoveIconsGoal).durationSeconds;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            _timeLeft--;
            if (_timeLeft <= 0 && !(goal as TimedRemoveIconsGoal).isCompleted) {
              (goal as TimedRemoveIconsGoal).onTimeExpired();
              _timer?.cancel();
            }
          });
        });
      } else {
        _timeLeft = 0;
      }
    });
  }

  void _generateGrid() {
    final rand = Random();
    // Déterminer le type et la quantité de tuile spéciale à générer
    String? specialType;
    int specialCount = 0;
    bool hasTraps = false;
    if (goal is RemoveIconsGoal) {
      final type = (goal as RemoveIconsGoal).iconType;
      const specialTypes = [
        'timer_chip',
        'signal_jammer',
        'emp_pulse',
        'trojan',
        'magnet_link',
        'encrypted_link',
        'quantum_loop',
      ];
      if (specialTypes.contains(type)) {
        specialType = type;
        specialCount = (goal as RemoveIconsGoal).targetCount;
      }
    } else if (goal is TimedRemoveIconsGoal) {
      final type = (goal as TimedRemoveIconsGoal).iconType;
      const specialTypes = [
        'timer_chip',
        'signal_jammer',
        'emp_pulse',
        'trojan',
        'magnet_link',
        'encrypted_link',
        'quantum_loop',
      ];
      if (specialTypes.contains(type)) {
        specialType = type;
        specialCount = (goal as TimedRemoveIconsGoal).targetCount;
      }
    }
    // Détection des pièges (si le niveau a Pieges = Yes)
    if (level.goal is RemoveIconsGoal || level.goal is TimedRemoveIconsGoal) {
      // On récupère la ligne du niveau dans le CSV via le nom (provisoire, à améliorer si besoin)
      final nameLower = level.name.toLowerCase();
      // Heuristique : si le nom contient "trap", "virus", "power" ou si le niveau est connu pour avoir des pièges
      if (nameLower.contains('trap') || nameLower.contains('virus') || nameLower.contains('power') || nameLower.contains('piège')) {
        hasTraps = true;
      }
      // TODO : idéalement, passer le flag Pieges depuis le parsing
    }
    // Générer la liste plate de tuiles à placer
    List<custom.GridTile> tiles = [];
    // 1. Ajouter les tuiles spéciales si besoin
    if (specialType != null && specialCount > 0) {
      for (int i = 0; i < specialCount; i++) {
        tiles.add(_createSpecialTile(specialType));
      }
    }
    // 2. Ajouter les tuiles piège si besoin
    if (hasTraps) {
      for (int i = 0; i < 2; i++) {
        tiles.add(custom.TrapHoleTile());
        tiles.add(custom.VirusInjectorTile());
        tiles.add(custom.PowerNodeTile());
      }
    }
    // 3. Compléter avec des tuiles classiques aléatoires
    while (tiles.length < GridBoard.gridSize * GridBoard.gridSize) {
      int iconIdx = rand.nextInt(GridBoard.iconAssets.length);
      tiles.add(custom.BasicGridTile(
        assetPath: GridBoard.iconAssets[iconIdx],
        type: _iconTypeFromIdx(iconIdx),
      ));
    }
    // 4. Mélanger la liste pour répartir les tuiles spéciales/pièges
    tiles.shuffle(rand);
    // 5. Remplir la grille
    grid = List.generate(GridBoard.gridSize, (row) =>
      List.generate(GridBoard.gridSize, (col) {
        return tiles[row * GridBoard.gridSize + col];
      })
    );
    selected.clear();
    // Après avoir généré la grille, détecter les tuiles spéciales non encore vues
    final specialsInGrid = <String>{};
    for (var row in grid) {
      for (var tile in row) {
        if (tile != null && tile.isSpecial) {
          specialsInGrid.add(tile.type);
        }
      }
    }
    final newSpecial = specialsInGrid.difference(_discoveredSpecials).firstWhere(
      (type) => specialTileInfo.containsKey(type),
      orElse: () => '',
    );
    if (newSpecial.isNotEmpty) {
      setState(() {
        _pendingSpecialToShow = newSpecial;
      });
    }
  }

  /// Crée une instance de tuile spéciale selon le type
  custom.GridTile _createSpecialTile(String type) {
    switch (type) {
      case 'timer_chip':
        return custom.TimerChipTile(initialTimer: 5);
      case 'signal_jammer':
        return custom.SignalJammerTile();
      case 'emp_pulse':
        return custom.EmpPulseTile();
      case 'trojan':
        return custom.TrojanTile();
      case 'magnet_link':
        return custom.MagnetLinkTile();
      case 'encrypted_link':
        return custom.EncryptedLinkTile();
      case 'quantum_loop':
        return custom.QuantumLoopTile();
      default:
        return custom.BasicGridTile(assetPath: '', type: type);
    }
  }

  String _iconTypeFromIdx(int idx) {
    switch (idx) {
      case 0:
        return 'lock';
      case 1:
        return 'firewall';
      case 2:
        return 'ai_chip';
      case 3:
        return 'bug';
      case 4:
        return 'warning';
      case 5:
        return 'save_disk';
      case 6:
        return 'node_chain';
      default:
        return 'icon';
    }
  }

  // Ajoute une fonction pour obtenir l'asset à partir du type
  String? _iconAssetFromType(String type) {
    switch (type) {
      case 'lock':
        return GridBoard.iconAssets[0];
      case 'firewall':
        return GridBoard.iconAssets[1];
      case 'ai_chip':
        return GridBoard.iconAssets[2];
      case 'bug':
        return GridBoard.iconAssets[3];
      case 'warning':
        return GridBoard.iconAssets[4];
      case 'save_disk':
        return GridBoard.iconAssets[5];
      case 'node_chain':
        return GridBoard.iconAssets[6];
      case 'timer_chip':
        return 'assets/icons/Timer_Chip.png';
      case 'signal_jammer':
        return 'assets/icons/Signal_Jammer.png';
      case 'emp_pulse':
        return 'assets/icons/EMP_Pulse.png';
      case 'trojan':
        return 'assets/icons/Trojan.png';
      case 'magnet_link':
        return 'assets/icons/Magnet_Link.png';
      case 'encrypted_link':
        return 'assets/icons/Encrypted_Link.png';
      case 'quantum_loop':
        return 'assets/icons/Quantum_Loop.png';
      case 'virus_injector':
        return 'assets/icons/Virus_Injector.png';
      case 'power_node':
        return 'assets/icons/Power_node.png';
      case 'trap_hole':
        return 'assets/icons/trap_hole.png';
      default:
        return null;
    }
  }

  void _removeTiles(List<Offset> tiles) {
    // Débloquer toutes les tuiles cachées par Signal Jammer
    setState(() {
      _hiddenTiles.clear();
    });
    final removedTypes = <String>[];
    final empPulseToTrigger = <Offset>[];
    final specialEffects = <Map<String, dynamic>>[];
    setState(() {
      for (final pos in tiles) {
        final tile = grid[pos.dx.toInt()][pos.dy.toInt()];
        if (tile != null) {
          _pendingAnimations.add(_PendingAnimation(pos, tile.assetPath));
          // Encrypted Link : ne compter que si déjà décryptée
          if (tile is custom.EncryptedLinkTile) {
            if (tile.decrypted) {
              removedTypes.add(tile.type);
            }
          } else {
            removedTypes.add(tile.type);
          }
          // Détecter EMP Pulse et préparer l'effet
          if (tile is custom.EmpPulseTile) {
            empPulseToTrigger.add(pos);
          }
          // Déclencher l'effet spécial/piège si besoin
          if (tile.isSpecial) {
            tile.applyEffect(pos.dx.toInt(), pos.dy.toInt(), (effect, row, col) {
              specialEffects.add({'effect': effect, 'row': row, 'col': col});
            });
          }
        }
      }
      selected.clear();
      isDragging = false;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      setState(() {
        for (final pos in empPulseToTrigger) {
          _triggerEmpPulse(pos.dx.toInt(), pos.dy.toInt());
        }
        // Appliquer les autres effets spéciaux/pièges
        for (final eff in specialEffects) {
          _triggerSpecialEffect(eff['effect'], eff['row'], eff['col']);
        }
        for (final pos in tiles) {
          // Ne pas supprimer les Trap Hole
          final tile = grid[pos.dx.toInt()][pos.dy.toInt()];
          if (tile is custom.TrapHoleTile) continue;
          // Encrypted Link : nécessite deux suppressions
          if (tile is custom.EncryptedLinkTile && !tile.decrypted) {
            tile.decrypted = true;
            continue;
          }
          grid[pos.dx.toInt()][pos.dy.toInt()] = null;
        }
        _pendingAnimations.removeWhere((anim) => tiles.contains(anim.pos));
        score += 10 * tiles.length;
        movesLeft--;
        goal.onIconsRemoved(removedTypes);
        _decrementAllTimers();
        _checkTimerChips();
        _dropAndFill();
      });
    });
  }

  /// Applique l'effet EMP Pulse : supprime toute la ligne et colonne de la tuile
  void _triggerEmpPulse(int row, int col) {
    final highlights = <Offset>{};
    for (int i = 0; i < GridBoard.gridSize; i++) {
      highlights.add(Offset(row.toDouble(), i.toDouble())); // ligne
      highlights.add(Offset(i.toDouble(), col.toDouble())); // colonne
    }
    setState(() {
      _empPulseHighlight = highlights;
    });
    for (int i = 0; i < GridBoard.gridSize; i++) {
      // Supprimer la ligne
      if (grid[row][i] != null) {
        grid[row][i] = null;
      }
      // Supprimer la colonne
      if (grid[i][col] != null) {
        grid[i][col] = null;
      }
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _empPulseHighlight.clear();
      });
    });
  }

  bool _canInteract() {
    if (goal is TimedRemoveIconsGoal) {
      return _timeLeft > 0 && !(goal as TimedRemoveIconsGoal).isFailed;
    } else {
      return movesLeft > 0;
    }
  }

  void _startDrag(Offset localPos) {
    if (goal.isCompleted || !_canInteract()) return;
    final pos = _offsetToGrid(localPos);
    if (pos == null) return;
    setState(() {
      selected = [pos];
      isDragging = true;
    });
  }

  void _updateDrag(Offset localPos) {
    if (!isDragging || goal.isCompleted || !_canInteract()) return;
    final pos = _offsetToGrid(localPos);
    if (pos == null) return;
    if (selected.isEmpty) return;
    final firstTile = grid[selected.first.dx.toInt()][selected.first.dy.toInt()];
    final currentTile = grid[pos.dx.toInt()][pos.dy.toInt()];
    if (firstTile == null || currentTile == null) return;
    if (currentTile.type != firstTile.type) return;
    if (selected.contains(pos)) return;
    if (!_isAdjacent(selected.last, pos)) return;
    setState(() {
      selected.add(pos);
    });
  }

  void _endDrag() {
    if (!isDragging) return;
    if (selected.length >= 2) {
      final firstIdx = grid[selected.first.dx.toInt()][selected.first.dy.toInt()];
      _removeTiles(List.of(selected));
      isDragging = false;
    } else {
      setState(() {
        selected.clear();
        isDragging = false;
        if (movesLeft > 0) movesLeft--;
      });
    }
  }

  void _onTileTap(int row, int col) {
    if (goal.isCompleted || !_canInteract()) return;
    if (selected.isEmpty) {
      setState(() {
        selected = [Offset(row.toDouble(), col.toDouble())];
      });
      return;
    }
    if (selected.length == 1) {
      final first = selected.first;
      if (!_isAdjacent(first, Offset(row.toDouble(), col.toDouble())) || selected.contains(Offset(row.toDouble(), col.toDouble()))) {
        setState(() => selected.clear());
        return;
      }
      final firstTile = grid[first.dx.toInt()][first.dy.toInt()];
      final currentTile = grid[row][col];
      if (firstTile == null || currentTile == null) return;
      if (currentTile.type == firstTile.type) {
        _removeTiles([first, Offset(row.toDouble(), col.toDouble())]);
      } else {
        setState(() {
          selected.clear();
          if (!(goal is TimedRemoveIconsGoal)) movesLeft--;
        });
      }
      return;
    }
    setState(() => selected.clear());
  }

  bool _isAdjacent(Offset a, Offset b) {
    final dr = (a.dx - b.dx).abs();
    final dc = (a.dy - b.dy).abs();
    // Pour l’instant, uniquement vertical/horizontal. Pour activer la diagonale plus tard :
    // return (dr == 1 && dc == 0) || (dr == 0 && dc == 1) || (dr == 1 && dc == 1);
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }

  void _onValidateSelection() {
    if (selected.length < 2) {
      setState(() => selected.clear());
      return;
    }
    // Supprimer les tuiles sélectionnées
    setState(() {
      for (final pos in selected) {
        grid[pos.dx.toInt()][pos.dy.toInt()] = null; // null = vide
      }
      selected.clear();
      _dropAndFill();
    });
  }

  void _dropAndFill() {
    final rand = Random();
    for (int col = 0; col < GridBoard.gridSize; col++) {
      // 1. Récupérer les tuiles non null de bas en haut
      List<custom.GridTile> nonEmpty = [];
      for (int row = GridBoard.gridSize - 1; row >= 0; row--) {
        if (grid[row][col] != null) {
          nonEmpty.add(grid[row][col]!);
        }
      }
      // 2. Compléter avec des nouvelles tuiles aléatoires en haut
      while (nonEmpty.length < GridBoard.gridSize) {
        int iconIdx = rand.nextInt(GridBoard.iconAssets.length);
        nonEmpty.add(custom.BasicGridTile(
          assetPath: GridBoard.iconAssets[iconIdx],
          type: _iconTypeFromIdx(iconIdx),
        ));
      }
      // 3. Réécrire la colonne dans la grille (de bas en haut)
      for (int row = GridBoard.gridSize - 1, idx = 0; row >= 0; row--, idx++) {
        grid[row][col] = nonEmpty[idx];
      }
    }
  }

  void _decrementAllTimers() {
    for (var row in grid) {
      for (var tile in row) {
        if (tile is custom.TimerChipTile) {
          tile.decrementTimer();
        }
      }
    }
  }

  void _checkTimerChips() {
    for (var row in grid) {
      for (var tile in row) {
        if (tile is custom.TimerChipTile && tile.timer <= 0) {
          // Effet : game over immédiat (à adapter selon la logique souhaitée)
          setState(() {
            movesLeft = 0;
          });
          return;
        }
      }
    }
  }

  bool _isSelected(int row, int col) {
    return selected.contains(Offset(row.toDouble(), col.toDouble()));
  }

  Offset? _offsetToGrid(Offset localPos) {
    final RenderBox? box = gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size.width / GridBoard.gridSize;
    final dx = (localPos.dx ~/ size).clamp(0, GridBoard.gridSize - 1);
    final dy = (localPos.dy ~/ size).clamp(0, GridBoard.gridSize - 1);
    return Offset(dy.toDouble(), dx.toDouble()); // row, col
  }

  void _triggerSpecialEffect(String effect, int row, int col) {
    switch (effect) {
      case 'trojan':
        _contaminateRandomNeighbor(row, col);
        break;
      case 'magnet_link':
        _attractNeighbors(row, col);
        break;
      case 'signal_jammer':
        _hideNeighbors(row, col);
        break;
      case 'encrypted_link':
        // Géré dans _removeTiles (état decrypted)
        break;
      case 'quantum_loop':
        // Joker : déjà géré par la logique de match
        break;
      case 'trap_hole':
        // Non supprimable : rien à faire
        break;
      case 'virus_injector':
        _contaminateAllNeighbors(row, col);
        break;
      case 'power_node':
        _applyPowerNodeBonus();
        break;
    }
  }

  void _contaminateRandomNeighbor(int row, int col) {
    final neighbors = _getNeighbors(row, col);
    if (neighbors.isNotEmpty) {
      final rand = Random();
      final pos = neighbors[rand.nextInt(neighbors.length)];
      grid[pos.dx.toInt()][pos.dy.toInt()] = custom.BasicGridTile(
        assetPath: _iconAssetFromType('bug')!,
        type: 'bug',
      );
    }
  }

  void _attractNeighbors(int row, int col) {
    final neighbors = _getNeighbors(row, col);
    setState(() {
      _magnetizedTiles = {Offset(row.toDouble(), col.toDouble()), ...neighbors};
    });
    for (final pos in neighbors) {
      final tile = grid[pos.dx.toInt()][pos.dy.toInt()];
      if (tile != null) {
        grid[row][col] = tile;
        grid[pos.dx.toInt()][pos.dy.toInt()] = null;
      }
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _magnetizedTiles.clear();
      });
    });
  }

  void _hideNeighbors(int row, int col) {
    final neighbors = _getNeighbors(row, col);
    setState(() {
      _hiddenTiles.addAll(neighbors);
    });
  }

  void _contaminateAllNeighbors(int row, int col) {
    final neighbors = _getNeighbors(row, col);
    for (final pos in neighbors) {
      grid[pos.dx.toInt()][pos.dy.toInt()] = custom.BasicGridTile(
        assetPath: _iconAssetFromType('bug')!,
        type: 'bug',
      );
    }
  }

  void _applyPowerNodeBonus() {
    // Bonus simple : +5 coups ou +10s si niveau à temps limité
    if (goal is TimedRemoveIconsGoal) {
      setState(() {
        _timeLeft += 10;
      });
    } else {
      setState(() {
        movesLeft += 5;
      });
    }
  }

  List<Offset> _getNeighbors(int row, int col) {
    final neighbors = <Offset>[];
    for (final d in [
      Offset(-1, 0), Offset(1, 0), Offset(0, -1), Offset(0, 1)
    ]) {
      final nr = row + d.dx.toInt();
      final nc = col + d.dy.toInt();
      if (nr >= 0 && nr < GridBoard.gridSize && nc >= 0 && nc < GridBoard.gridSize) {
        neighbors.add(Offset(nr.toDouble(), nc.toDouble()));
      }
    }
    return neighbors;
  }

  String _immersiveTitleForGoal(LevelGoal goal) {
    String type = '';
    int? count;
    if (goal is RemoveIconsGoal) {
      type = goal.iconType;
      count = goal.targetCount;
    } else if (goal is TimedRemoveIconsGoal) {
      type = goal.iconType;
      count = goal.targetCount;
    }
    switch (type) {
      case 'signal_jammer':
        return 'Signal Jammer Breach';
      case 'emp_pulse':
        return 'EMP Pulse Overload';
      case 'trojan':
        return 'Trojan Infiltration';
      case 'magnet_link':
        return 'Magnetized Network';
      case 'encrypted_link':
        return 'Encrypted Data Crack';
      case 'quantum_loop':
        return 'Quantum Loop Anomaly';
      case 'timer_chip':
        return 'Time Bomb Defusal';
      case 'bug':
        return 'Bug Hunt';
      case 'firewall':
        return 'Firewall Breach';
      case 'lock':
        return 'Lockdown';
      case 'ai_chip':
        return 'AI Core Extraction';
      case 'warning':
        return 'Warning Protocol';
      case 'node_chain':
        return 'Node Chain Disruption';
      case 'save_disk':
        return 'Data Recovery';
      default:
        return 'Mission Spéciale';
    }
  }

  void _onAcknowledgeSpecial() {
    if (_pendingSpecialToShow != null) {
      setState(() {
        _discoveredSpecials.add(_pendingSpecialToShow!);
        _pendingSpecialToShow = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (loadingError != null) {
      return Center(child: Text(loadingError!, style: const TextStyle(color: Colors.redAccent, fontSize: 20)));
    }
    // Déterminer l'icône de l'objectif si applicable
    String? goalIcon;
    if (goal is RemoveIconsGoal) {
      final type = (goal as RemoveIconsGoal).iconType;
      goalIcon = _iconAssetFromType(type);
    } else if (goal is TimedRemoveIconsGoal) {
      final type = (goal as TimedRemoveIconsGoal).iconType;
      goalIcon = _iconAssetFromType(type);
    }
    final levelNumber = levels.isNotEmpty ? (currentLevel + 1) : 1;
    final levelTotal = levels.length;
    final immersiveTitle = _immersiveTitleForGoal(goal);
    final levelObjective = goal.description;
    final levelProgress = 'Niveau $levelNumber/$levelTotal';
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  Text(
                    immersiveTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelObjective,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.1,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelProgress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.1,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            GoalHUD(
              score: score,
              goal: goal,
              iconAsset: goalIcon,
              movesLeft: movesLeft,
              timeLeft: goal is TimedRemoveIconsGoal ? _timeLeft : null,
            ),
            if ((goal is RemoveIconsGoal && movesLeft == 0 && !goal.isCompleted) ||
                (goal is TimedRemoveIconsGoal && (goal as TimedRemoveIconsGoal).isFailed))
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Game Over', style: TextStyle(fontSize: 24, color: Colors.redAccent)),
              ),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellSize = constraints.maxWidth / GridBoard.gridSize;
                      return Listener(
                        onPointerDown: (event) {
                          final box = gridKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final local = box.globalToLocal(event.position);
                            _startDrag(local);
                          }
                        },
                        onPointerMove: (event) {
                          final box = gridKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final local = box.globalToLocal(event.position);
                            _updateDrag(local);
                          }
                        },
                        onPointerUp: (_) => _endDrag(),
                        child: Stack(
                          children: [
                            GridView.builder(
                              key: gridKey,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: GridBoard.gridSize,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: GridBoard.gridSize * GridBoard.gridSize,
                              itemBuilder: (context, index) {
                                final row = index ~/ GridBoard.gridSize;
                                final col = index % GridBoard.gridSize;
                                final tile = grid[row][col];
                                if (tile == null) {
                                  return const SizedBox.shrink();
                                }
                                final isHidden = _hiddenTiles.contains(Offset(row.toDouble(), col.toDouble()));
                                final isMagnetized = _magnetizedTiles.contains(Offset(row.toDouble(), col.toDouble()));
                                final isEmpPulse = _empPulseHighlight.contains(Offset(row.toDouble(), col.toDouble()));
                                return Opacity(
                                  opacity: isHidden ? 0.3 : 1.0,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        decoration: isEmpPulse
                                            ? BoxDecoration(
                                                border: Border.all(color: Colors.cyanAccent, width: 6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.cyanAccent.withOpacity(0.7),
                                                    blurRadius: 16,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                                borderRadius: BorderRadius.circular(12),
                                              )
                                            : isMagnetized
                                                ? BoxDecoration(
                                                    border: Border.all(color: Colors.cyanAccent, width: 4),
                                                    borderRadius: BorderRadius.circular(12),
                                                  )
                                                : null,
                                        child: CyberTile(
                                          assetPath: tile.assetPath,
                                          isBeingRemoved: false,
                                          tile: tile,
                                        ),
                                      ),
                                      if (isHidden)
                                        const Positioned.fill(
                                          child: Center(
                                            child: Text(
                                              '?',
                                              style: TextStyle(
                                                color: Colors.tealAccent,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Overlay des animations de suppression
                            ..._pendingAnimations.map((anim) {
                              return Positioned(
                                left: anim.pos.dy * cellSize,
                                top: anim.pos.dx * cellSize,
                                width: cellSize,
                                height: cellSize,
                                child: CyberTile(
                                  assetPath: anim.assetPath,
                                  isBeingRemoved: true,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(_generateGrid);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (goal.isCompleted)
          VictoryDialog(
            onNext: () {
              _loadLevel(currentLevel + 1);
            },
          ),
        if ((goal is RemoveIconsGoal && movesLeft == 0 && !goal.isCompleted) ||
            (goal is TimedRemoveIconsGoal && (goal as TimedRemoveIconsGoal).isFailed))
          GameOverDialog(
            onRetry: () {
              _loadLevel(currentLevel);
            },
          ),
        if (_pendingSpecialToShow != null)
          SpecialTileIntroPopup(
            type: _pendingSpecialToShow!,
            info: specialTileInfo[_pendingSpecialToShow!]!,
            onAcknowledge: _onAcknowledgeSpecial,
          ),
      ],
    );
  }
}

class GoalHUD extends StatelessWidget {
  final int score;
  final int? movesLeft;
  final int? timeLeft;
  final LevelGoal goal;
  final String? iconAsset;
  const GoalHUD({
    super.key,
    required this.score,
    this.movesLeft,
    this.timeLeft,
    required this.goal,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.tealAccent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(Icons.score, color: Colors.tealAccent, size: 32),
              const SizedBox(width: 8),
              Text('Score: $score', style: const TextStyle(fontSize: 26, color: Colors.tealAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 24),
          if (timeLeft != null)
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.tealAccent, size: 32),
                const SizedBox(width: 8),
                Text('Time: $timeLeft s', style: const TextStyle(fontSize: 26, color: Colors.tealAccent, fontWeight: FontWeight.bold)),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.tealAccent, size: 32),
                const SizedBox(width: 8),
                Text('Moves: $movesLeft', style: const TextStyle(fontSize: 26, color: Colors.tealAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          const SizedBox(width: 24),
          Flexible(
            child: Row(
              children: [
                if (iconAsset != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.asset(iconAsset!, width: 36, height: 36),
                  ),
                Flexible(
                  child: Text(
                    goal.description,
                    style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpecialTileIntroPopup extends StatelessWidget {
  final String type;
  final Map<String, String> info;
  final VoidCallback onAcknowledge;
  const SpecialTileIntroPopup({required this.type, required this.info, required this.onAcknowledge, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.tealAccent, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withOpacity(0.3),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(info['asset']!, width: 96, height: 96),
              const SizedBox(height: 24),
              Text(
                info['title']!,
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                info['desc']!,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.1,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                ),
                onPressed: onAcknowledge,
                child: const Text('Compris !'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exemple d'utilisation :
/// GridBoard() à placer dans un Scaffold.body 