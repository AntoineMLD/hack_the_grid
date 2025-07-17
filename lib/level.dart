import 'level_goal.dart';

class Level {
  final String name;
  final LevelGoal goal;
  final int moves;

  Level({required this.name, required this.goal, required this.moves});
}

// Exemple de liste de niveaux (à importer dans GridBoard)
final List<Level> levels = [
  Level(
    name: 'Firewall Breach',
    goal: RemoveIconsGoal(iconIndex: 1, targetCount: 10), // 10 firewalls
    moves: 20,
  ),
  Level(
    name: 'Bug Hunt',
    goal: RemoveIconsGoal(iconIndex: 3, targetCount: 8), // 8 bugs
    moves: 18,
  ),
  Level(
    name: 'Lockdown',
    goal: RemoveIconsGoal(iconIndex: 0, targetCount: 12), // 12 locks
    moves: 22,
  ),
]; 