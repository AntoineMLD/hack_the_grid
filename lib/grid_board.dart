import 'dart:math';
import 'package:flutter/material.dart';
import 'level_goal.dart';

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

class _GridBoardState extends State<GridBoard> {
  late List<List<int>> grid; // indices d'icônes
  List<Offset> selected = []; // positions sélectionnées
  int score = 0;
  int movesLeft = 20;
  late LevelGoal goal;

  @override
  void initState() {
    super.initState();
    _generateGrid();
    // Objectif : supprimer 10 firewalls (index 1)
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

  void _onTileTap(int row, int col) {
    final iconIdx = grid[row][col];
    final pos = Offset(row.toDouble(), col.toDouble());
    if (goal.isCompleted || movesLeft <= 0) return;
    if (selected.isEmpty) {
      setState(() {
        selected = [pos];
      });
      return;
    }
    if (selected.length == 1) {
      final first = selected.first;
      if (!_isAdjacent(first, pos) || selected.contains(pos)) {
        setState(() => selected.clear());
        return;
      }
      final firstIdx = grid[first.dx.toInt()][first.dy.toInt()];
      if (iconIdx == firstIdx) {
        setState(() {
          // Supprimer les deux tuiles
          grid[first.dx.toInt()][first.dy.toInt()] = -1;
          grid[row][col] = -1;
          selected.clear();
          score += 10;
          movesLeft--;
          goal.onIconsRemoved([firstIdx, iconIdx]);
          _dropAndFill();
        });
      } else {
        setState(() {
          selected.clear();
          movesLeft--;
        });
      }
      return;
    }
    // Si déjà deux tuiles sélectionnées, reset
    setState(() => selected.clear());
  }

  bool _isAdjacent(Offset a, Offset b) {
    final dr = (a.dx - b.dx).abs();
    final dc = (a.dy - b.dy).abs();
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
      int empty = GridBoard.gridSize - 1;
      for (int row = GridBoard.gridSize - 1; row >= 0; row--) {
        if (grid[row][col] != -1) {
          grid[empty][col] = grid[row][col];
          if (empty != row) grid[row][col] = -1;
          empty--;
        }
      }
      // Remplir le haut
      for (int row = empty; row >= 0; row--) {
        grid[row][col] = rand.nextInt(GridBoard.iconAssets.length);
      }
    }
  }

  bool _isSelected(int row, int col) {
    return selected.contains(Offset(row.toDouble(), col.toDouble()));
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
              child: GridView.builder(
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
                  return GestureDetector(
                    onTap: () => _onTileTap(row, col),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isSelected(row, col)
                            ? Colors.tealAccent.withOpacity(0.5)
                            : Colors.black.withOpacity(0.3),
                        border: Border.all(
                          color: _isSelected(row, col)
                              ? Colors.tealAccent
                              : Colors.teal,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          GridBoard.iconAssets[iconIdx],
                          fit: BoxFit.contain,
                        ),
                      ),
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