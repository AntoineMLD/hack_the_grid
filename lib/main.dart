import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'grid_board.dart';

void main() {
  runApp(const HackTheGridApp());
}

/// Root widget for Hack The Grid.
/// Applies VT323 font and sets up the splash screen.
class HackTheGridApp extends StatelessWidget {
  const HackTheGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hack The Grid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
        useMaterial3: true,
        fontFamily: 'VT323',
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Simple splash screen with background and logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Après 2 secondes, naviguer vers la grille de jeu
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GridScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/grid_background_circuit.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/splash_screen.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 32),
                const Text(
                  'HACK THE GRID',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.tealAccent,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cyber Puzzle Game',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
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

/// Écran principal affichant la grille de jeu 6x6 avec des icônes aléatoires.
class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hack The Grid'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.tealAccent,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/grid_background_grid.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const GridBoard(),
      ),
    );
  }
}

// Prochaine étape : créer la grille de jeu interactive sur un nouvel écran.
// Ce squelette est prêt à évoluer, tout en restant simple et lisible.
