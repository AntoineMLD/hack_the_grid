import 'package:flutter/material.dart';

/// Popup de briefing de mission cyberpunk avec bouton cliquable sur l'image.
/// Affiche l'image 'assets/startmission.png', le titre immersif, l'objectif, et détecte le clic sur la zone du bouton.
/// Affiche un effet visuel lors du clic et appelle [onStart] si le bouton est pressé.
class MissionBriefingPopup extends StatefulWidget {
  final VoidCallback onStart;
  final String immersiveTitle;
  final String objective;
  final String? levelInfo;
  const MissionBriefingPopup({
    required this.onStart,
    required this.immersiveTitle,
    required this.objective,
    this.levelInfo,
    super.key,
  });

  @override
  State<MissionBriefingPopup> createState() => _MissionBriefingPopupState();
}

class _MissionBriefingPopupState extends State<MissionBriefingPopup> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Zone exacte du bouton sur l'image 768x768
  final Rect buttonRect = Rect.fromLTWH(174, 620, 420, 70);
  final double imageWidth = 768;
  final double imageHeight = 768;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    final local = details.localPosition;
    final scaleX = constraints.maxWidth / imageWidth;
    final scaleY = constraints.maxHeight / imageHeight;
    final scaledRect = Rect.fromLTWH(
      buttonRect.left * scaleX,
      buttonRect.top * scaleY,
      buttonRect.width * scaleX,
      buttonRect.height * scaleY,
    );
    if (scaledRect.contains(local)) {
      setState(() => _pressed = true);
    }
  }

  void _onTapUp(TapUpDetails details, BoxConstraints constraints) {
    final local = details.localPosition;
    final scaleX = constraints.maxWidth / imageWidth;
    final scaleY = constraints.maxHeight / imageHeight;
    final scaledRect = Rect.fromLTWH(
      buttonRect.left * scaleX,
      buttonRect.top * scaleY,
      buttonRect.width * scaleX,
      buttonRect.height * scaleY,
    );
    if (scaledRect.contains(local)) {
      _fadeController.reverse().then((_) => widget.onStart());
    }
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapDown: (d) => _onTapDown(d, constraints),
          onTapUp: (d) => _onTapUp(d, constraints),
          onTapCancel: () => setState(() => _pressed = false),
          child: Stack(
            children: [
              // Overlay sombre
              Container(color: Colors.black.withOpacity(0.95)),
              // Image de fond
              Image.asset('assets/startmission.png', fit: BoxFit.contain, width: double.infinity, height: double.infinity),
              // Overlay infos mission
              Positioned(
                left: 0,
                right: 0,
                top: 60,
                child: Column(
                  children: [
                    Text(
                      widget.immersiveTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.objective,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.1,
                        shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.levelInfo != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.levelInfo!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.1,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              // Effet visuel sur le bouton
              if (_pressed)
                Positioned(
                  left: buttonRect.left * constraints.maxWidth / imageWidth,
                  top: buttonRect.top * constraints.maxHeight / imageHeight,
                  width: buttonRect.width * constraints.maxWidth / imageWidth,
                  height: buttonRect.height * constraints.maxHeight / imageHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.cyanAccent, width: 3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 