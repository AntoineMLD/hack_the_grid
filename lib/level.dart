import 'level_goal.dart';
import 'levels/level_loader.dart';

class Level {
  final String name;
  final LevelGoal goal;
  final int moves;

  Level({required this.name, required this.goal, required this.moves});
}

/// Charge dynamiquement la liste des niveaux à partir du CSV.
/// Utilisation :
///   final levels = await getLevels();
Future<List<Level>> getLevels() async {
  // Adapter le chemin si besoin selon la plateforme (ici, racine du projet)
  return await loadLevelsFromCsv('Liste_des_100_niveaux_Hack_the_Grid.csv');
} 