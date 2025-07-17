import 'dart:math';
import 'package:flutter/material.dart';
import 'level_goal.dart';
import 'cyber_tile.dart';

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

class _GridBoardState extends State<GridBoard> {
  late List<List<int>> grid; // indices d'icônes
  List<Offset> selected = [];
  int score = 0;
  int movesLeft = 20;
  late LevelGoal goal;
  bool isDragging = false;
  GlobalKey gridKey = GlobalKey();
  final List<_PendingAnimation> _pendingAnimations = [];

  // Stocke le dernier type d'icône supprimé pour chaque position animée
  final Map<Offset, int> _lastRemovedIconIdx = {};

  int? _lastRemovedIconIdxFor(Offset pos) => _lastRemovedIconIdx[pos];

  @override
  void initState() {
    super.initState();
    _generateGrid();
    goal = RemoveIconsGoal(iconIndex: 1, targetCount: 10);
  }

  void _generateGrid() {
    final rand = Random();
    grid = List.generate(GridBoard.gridSize, (_) =>
      List.generate(GridBoard.gridSize, (_) => rand.nextInt(GridBoard.iconAssets.length))
    );
    selected.clear();
    score = 0;
    movesLeft = 20;
    goal = RemoveIconsGoal(iconIndex: 1, targetCount: 10);
  }

  void _removeTiles(List<Offset> tiles, int iconIdx) {
    setState(() {
      for (final pos in tiles) {
        _pendingAnimations.add(_PendingAnimation(pos, GridBoard.iconAssets[iconIdx]));
        grid[pos.dx.toInt()][pos.dy.toInt()] = -1;
      }
      score += 10 * tiles.length;
      movesLeft--;
      goal.onIconsRemoved(List.filled(tiles.length, iconIdx));
      selected.clear();
      _dropAndFill();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      setState(() {
        _pendingAnimations.removeWhere((anim) => tiles.contains(anim.pos));
      });
    });
  }

  void _startDrag(Offset localPos) {
    if (goal.isCompleted || movesLeft <= 0) return;
    final pos = _offsetToGrid(localPos);
    if (pos == null) return;
    setState(() {
      selected = [pos];
      isDragging = true;
    });
  }

  void _updateDrag(Offset localPos) {
    if (!isDragging || goal.isCompleted || movesLeft <= 0) return;
    final pos = _offsetToGrid(localPos);
    if (pos == null) return;
    if (selected.isEmpty) return;
    final firstIdx = grid[selected.first.dx.toInt()][selected.first.dy.toInt()];
    final iconIdx = grid[pos.dx.toInt()][pos.dy.toInt()];
    if (iconIdx != firstIdx) return;
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
      _removeTiles(List.of(selected), firstIdx);
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
    // Pour compatibilité tap (sélection de 2 tuiles)
    if (goal.isCompleted || movesLeft <= 0) return;
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
      final firstIdx = grid[first.dx.toInt()][first.dy.toInt()];
      final iconIdx = grid[row][col];
      if (iconIdx == firstIdx) {
        _removeTiles([first, Offset(row.toDouble(), col.toDouble())], iconIdx);
      } else {
        setState(() {
          selected.clear();
          movesLeft--;
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
        grid[pos.dx.toInt()][pos.dy.toInt()] = -1; // -1 = vide
      }
      selected.clear();
      _dropAndFill();
    });
  }

  void _dropAndFill() {
    final rand = Random();
    for (int col = 0; col < GridBoard.gridSize; col++) {
      // 1. Récupérer les tuiles non -1 de bas en haut
      List<int> nonEmpty = [];
      for (int row = GridBoard.gridSize - 1; row >= 0; row--) {
        if (grid[row][col] != -1) {
          nonEmpty.add(grid[row][col]);
        }
      }
      // 2. Compléter avec des nouvelles tuiles aléatoires en haut
      while (nonEmpty.length < GridBoard.gridSize) {
        nonEmpty.add(rand.nextInt(GridBoard.iconAssets.length));
      }
      // 3. Réécrire la colonne dans la grille (de bas en haut)
      for (int row = GridBoard.gridSize - 1, idx = 0; row >= 0; row--, idx++) {
        grid[row][col] = nonEmpty[idx];
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HUD
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Score: $score', style: const TextStyle(fontSize: 20, color: Colors.tealAccent)),
              Text('Moves: $movesLeft', style: const TextStyle(fontSize: 20, color: Colors.tealAccent)),
              Flexible(child: Text(goal.description, style: const TextStyle(fontSize: 16, color: Colors.white), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        if (goal.isCompleted)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('🎉 Goal completed! 🎉', style: TextStyle(fontSize: 24, color: Colors.greenAccent)),
          ),
        if (movesLeft == 0 && !goal.isCompleted)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Game Over', style: TextStyle(fontSize: 24, color: Colors.redAccent)),
          ),
        // Grille
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
                            final iconIdx = grid[row][col];
                            if (iconIdx == -1) {
                              return const SizedBox.shrink();
                            }
                            final assetPath = GridBoard.iconAssets[iconIdx];
                            return CyberTile(
                              assetPath: assetPath,
                              isBeingRemoved: false,
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
    );
  }
}

/// Exemple d'utilisation :
/// GridBoard() à placer dans un Scaffold.body 