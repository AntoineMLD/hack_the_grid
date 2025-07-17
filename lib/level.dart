import 'level_goal.dart';

class Level {
  final String name;
  final LevelGoal goal;
  final int moves;

  Level({required this.name, required this.goal, required this.moves});
}

// Progression douce : objectif +2 à +3 par niveau, moves -1 à -2
final List<Level> levels = [
  Level(
    name: 'Firewall Breach',
    goal: RemoveIconsGoal(iconIndex: 1, targetCount: 8), // 8 firewalls
    moves: 20,
  ),
  Level(
    name: 'Bug Hunt',
    goal: RemoveIconsGoal(iconIndex: 3, targetCount: 10), // 10 bugs
    moves: 19,
  ),
  Level(
    name: 'Lockdown',
    goal: RemoveIconsGoal(iconIndex: 0, targetCount: 12), // 12 locks
    moves: 18,
  ),
  Level(
    name: 'AI Core',
    goal: RemoveIconsGoal(iconIndex: 2, targetCount: 14), // 14 AI chips
    moves: 17,
  ),
  Level(
    name: 'Warning Protocol',
    goal: RemoveIconsGoal(iconIndex: 4, targetCount: 16), // 16 warnings
    moves: 16,
  ),
  Level(
    name: 'Node Chain',
    goal: RemoveIconsGoal(iconIndex: 6, targetCount: 18), // 18 node chains
    moves: 15,
  ),
]; 