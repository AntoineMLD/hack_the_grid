import 'package:flutter/material.dart';

/// Widget animé pour effet de suppression cyberpunk (pulse, scale, glitch, fade).
class CyberTile extends StatefulWidget {
  final String assetPath;
  final bool isBeingRemoved;
  final VoidCallback? onAnimationEnd;

  const CyberTile({
    super.key,
    required this.assetPath,
    required this.isBeingRemoved,
    this.onAnimationEnd,
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
                child: child,
              ),
            ),
          ),
        );
      },
      child: Image.asset(widget.assetPath, fit: BoxFit.contain),
    );
  }
} 