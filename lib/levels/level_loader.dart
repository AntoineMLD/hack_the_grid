import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../level.dart';
import '../level_goal.dart';

/// Charge dynamiquement la liste des niveaux à partir d'un fichier CSV.
/// [path] : chemin du fichier CSV (ex: 'Liste_des_100_niveaux_Hack_the_Grid.csv')
/// Retourne une liste de Level.
Future<List<Level>> loadLevelsFromCsv(String path) async {
  final file = File(path);
  final csvString = await file.readAsString();
  final rows = const CsvToListConverter(eol: '\n').convert(csvString, eol: '\n');
  if (rows.isEmpty) return [];
  final header = rows.first;
  final levels = <Level>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 7) continue; // Skip malformed lines
    levels.add(parseLevelFromCsvLine(row));
  }
  return levels;
}

/// Parse une ligne du CSV en un objet Level.
Level parseLevelFromCsvLine(List<dynamic> columns) {
  final name = columns[1].toString();
  final objectif = columns[2].toString().trim().toLowerCase();
  final quantite = int.tryParse(columns[3].toString()) ?? 0;
  final coupsStr = columns[4].toString().toLowerCase();
  final pieges = columns[5].toString().toLowerCase();
  final tempsLimite = columns[6].toString().toLowerCase();

  // Mapping objectif -> type de tuile
  final iconType = _mapObjectifToIconType(objectif);

  // Détection du mode temps limité
  final isTimed = tempsLimite == 'yes' || coupsStr.contains('temps');
  if (isTimed) {
    // Par défaut, 60 secondes (à affiner si info dans le CSV)
    final goal = TimedRemoveIconsGoal(iconType: iconType, targetCount: quantite, durationSeconds: 60);
    return Level(name: name, goal: goal, moves: 0);
  } else {
    final coups = int.tryParse(columns[4].toString()) ?? 0;
    final goal = RemoveIconsGoal(iconType: iconType, targetCount: quantite);
    return Level(name: name, goal: goal, moves: coups);
  }
}

/// Mapping explicite entre le nom d'objectif du CSV et le type de tuile interne.
String _mapObjectifToIconType(String objectif) {
  switch (objectif) {
    case 'timer chip':
      return 'timer_chip';
    case 'firewall':
      return 'firewall';
    case 'lock':
      return 'lock';
    case 'ai chip':
      return 'ai_chip';
    case 'bug':
      return 'bug';
    case 'warning':
      return 'warning';
    case 'save disk':
      return 'save_disk';
    case 'node chain':
      return 'node_chain';
    case 'emp pulse':
      return 'emp_pulse';
    case 'trojan':
      return 'trojan';
    case 'magnet link':
      return 'magnet_link';
    case 'signal jammer':
      return 'signal_jammer';
    case 'encrypted link':
      return 'encrypted_link';
    case 'quantum loop':
      return 'quantum_loop';
    default:
      return objectif.replaceAll(' ', '_');
  }
} 