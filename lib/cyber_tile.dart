import 'package:flutter/material.dart';
import 'grid_tile.dart' as custom;

/// Widget animé pour effet de suppression cyberpunk (pulse, scale, glitch, fade).
class CyberTile extends StatefulWidget {
  final String assetPath;
  final bool isBeingRemoved;
  final VoidCallback? onAnimationEnd;
  final custom.GridTile? tile; // Permet de passer la tuile pour affichage spécial
  final String? highlightEffect; // Ajouté : effet visuel spécial

  const CyberTile({
    super.key,
    required this.assetPath,
    required this.isBeingRemoved,
    this.onAnimationEnd,
    this.tile,
    this.highlightEffect,
  });

  @override
  State<CyberTile> createState() => _CyberTileState();
}

class _CyberTileState extends State<CyberTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Color?> _colorAnim;
  late Animation<double> _glitchAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.7).chain(CurveTween(curve: Curves.easeIn)), weight: 70),
    ]).animate(_controller);
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0)),
    );
    _colorAnim = ColorTween(begin: Colors.transparent, end: Colors.tealAccent.withOpacity(0.7)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );
    _glitchAnim = Tween<double>(begin: 0.0, end: 8.0).chain(CurveTween(curve: Curves.elasticIn)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6)),
    );
    if (widget.isBeingRemoved) {
      _controller.forward();
    }
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onAnimationEnd != null) {
        widget.onAnimationEnd!();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CyberTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBeingRemoved && !oldWidget.isBeingRemoved) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tileImage = Image.asset(widget.assetPath, fit: BoxFit.contain);

    // Effet visuel spécial selon highlightEffect
    if (widget.highlightEffect == 'emp_pulse') {
      tileImage = AnimatedOpacity(
        opacity: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.7),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
          child: tileImage,
        ),
      );
    } else if (widget.highlightEffect == 'magnet') {
      tileImage = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.1),
        duration: const Duration(milliseconds: 300),
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: tileImage,
      );
    } else if (widget.highlightEffect == 'trojan' || widget.highlightEffect == 'virus_injector') {
      tileImage = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.15),
        duration: const Duration(milliseconds: 250),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.pinkAccent.withOpacity(0.5), BlendMode.modulate),
            child: child!,
          ),
        ),
        child: tileImage,
      );
    } else if (widget.highlightEffect == 'signal_jammer') {
      tileImage = AnimatedOpacity(
        opacity: 0.5 + 0.5 * (DateTime.now().millisecond % 2),
        duration: const Duration(milliseconds: 100),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.tealAccent.withOpacity(0.3), BlendMode.screen),
          child: tileImage,
        ),
      );
    } else if (widget.highlightEffect == 'encrypted_link') {
      tileImage = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.2),
        duration: const Duration(milliseconds: 250),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.cyanAccent.withOpacity(0.5), BlendMode.lighten),
            child: child!,
          ),
        ),
        child: tileImage,
      );
    } else if (widget.highlightEffect == 'quantum_loop') {
      tileImage = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.1),
        duration: const Duration(milliseconds: 400),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.purpleAccent.withOpacity(0.4), BlendMode.screen),
            child: child!,
          ),
        ),
        child: tileImage,
      );
    } else if (widget.highlightEffect == 'trap_hole') {
      tileImage = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.95),
        duration: const Duration(milliseconds: 120),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.redAccent.withOpacity(0.5), BlendMode.modulate),
            child: child!,
          ),
        ),
        child: tileImage,
      );
    } else if (widget.highlightEffect == 'power_node') {
      tileImage = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.15),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.yellowAccent.withOpacity(0.5), BlendMode.screen),
            child: child!,
          ),
        ),
        child: tileImage,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: Offset(_glitchAnim.value * (_controller.value < 0.5 ? 1 : -1), 0),
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: _colorAnim.value ?? Colors.transparent,
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    tileImage,
                   if (widget.tile is custom.TimerChipTile)
                     Positioned(
                       bottom: 4,
                       right: 4,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                           color: Colors.black.withOpacity(0.7),
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.tealAccent, width: 1),
                         ),
                         child: Text(
                           (widget.tile as custom.TimerChipTile).timer.toString(),
                           style: const TextStyle(
                             color: Colors.tealAccent,
                             fontWeight: FontWeight.bold,
                             fontSize: 16,
                             shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                           ),
                         ),
                       ),
                     ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: null,
    );
  }
} 