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
    name: 'Chain Reaction 1',
    goal: RemoveIconsGoal(iconType: 'timer_chip', targetCount: 6), // 6 Timer Chips
    moves: 25,
  ),
  Level(
    name: 'Bug Hunt',
    goal: RemoveIconsGoal(iconType: 'bug', targetCount: 10), // 10 bugs
    moves: 19,
  ),
  Level(
    name: 'Lockdown',
    goal: RemoveIconsGoal(iconType: 'lock', targetCount: 12), // 12 locks
    moves: 18,
  ),
  Level(
    name: 'AI Core',
    goal: RemoveIconsGoal(iconType: 'ai_chip', targetCount: 14), // 14 AI chips
    moves: 17,
  ),
  Level(
    name: 'Warning Protocol',
    goal: RemoveIconsGoal(iconType: 'warning', targetCount: 16), // 16 warnings
    moves: 16,
  ),
  Level(
    name: 'Node Chain',
    goal: RemoveIconsGoal(iconType: 'node_chain', targetCount: 18), // 18 node chains
    moves: 15,
  ),
]; 