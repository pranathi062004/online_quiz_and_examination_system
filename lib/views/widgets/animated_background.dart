import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Generate random soft glow background particles
    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle());
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
        for (final p in _particles) {
          p.update();
        }
        return Stack(
          children: [
            // Dark base gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Slate background
                    Color(0xFF020617), // Deep slate black
                    Color(0xFF1E1E38), // Deep purple glow base
                  ],
                ),
              ),
            ),
            // Custom Painter for soft glow drift particles
            Positioned.fill(
              child: CustomPaint(
                painter: _ParticlePainter(_particles),
              ),
            ),
            // Backdrop blur to diffuse particles into beautiful, dynamic gradient meshes
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox.shrink(),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _Particle {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double radius = 0;
  double opacity = 0;
  late Color color;
  static final math.Random _random = math.Random();

  _Particle() {
    x = _random.nextDouble();
    y = _random.nextDouble();
    radius = 120 + _random.nextDouble() * 180; // Large diffuse circles
    opacity = 0.04 + _random.nextDouble() * 0.08;
    vx = (_random.nextDouble() - 0.5) * 0.0006;
    vy = (_random.nextDouble() - 0.5) * 0.0006;
    
    // Choose between primary (indigo) and secondary (cyan) glow
    color = _random.nextBool() ? AppColors.primary : AppColors.secondary;
  }

  void update() {
    x += vx;
    y += vy;

    // Boundary bouncing
    if (x < -0.2 || x > 1.2) vx = -vx;
    if (y < -0.2 || y > 1.2) vy = -vy;

    x = x.clamp(-0.3, 1.3);
    y = y.clamp(-0.3, 1.3);
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
        
      final position = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
