import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../styles/app_styles.dart';
import 'login_page.dart';
import 'register_page.dart';

// Erste Seite für nicht angemeldete Nutzer -- nur Titel + Anmelden/Registrieren.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _gradientController;
  late final AnimationController _networkController;

  @override
  void initState() {
    super.initState();
    // sanfte, endlos wiederholte Animation für den Hintergrund-Farbverlauf
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // langsame Bewegung der Netzwerk-Punkte im Hintergrund
    _networkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _networkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hintergrund: animierter Farbverlauf
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              final t = _gradientController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xff0f172a), const Color(0xff1e293b), t)!,
                      Color.lerp(const Color(0xff312e81), const Color(0xff0f172a), t)!,
                    ],
                  ),
                ),
              );
            },
          ),

          // darüber: sich bewegende Punkte + Verbindungslinien
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _networkController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _NetworkPainter(t: _networkController.value),
                );
              },
            ),
          ),

          // ganz oben: Titel + Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏠', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  const Text(
                    'Smart Room',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bitte melde dich an oder registriere dich,\num deinen Raum zu steuern.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: buttonStyle(Colors.blueAccent),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      child: const Text('Anmelden'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                      child: const Text('Registrieren'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ein Punkt im Netzwerk-Hintergrund, bewegt sich leicht um eine Basisposition
// (sin/cos statt fester Geschwindigkeit, damit die Animation sauber loopt)
class _NetworkNode {
  final double baseX;
  final double baseY;
  final double phase;
  final double radius;

  _NetworkNode({
    required this.baseX,
    required this.baseY,
    required this.phase,
    required this.radius,
  });

  Offset positionAt(double t, Size size) {
    final angle = t * 2 * math.pi;
    final dx = math.sin(angle + phase) * 0.05;
    final dy = math.cos(angle + phase * 1.3) * 0.05;
    return Offset((baseX + dx) * size.width, (baseY + dy) * size.height);
  }
}

class _NetworkPainter extends CustomPainter {
  final double t;

  // fester seed -- immer dasselbe, ruhige Muster statt bei jedem Rebuild neu
  static final List<_NetworkNode> _nodes = List.generate(28, (i) {
    final random = math.Random(i * 97);
    return _NetworkNode(
      baseX: random.nextDouble(),
      baseY: random.nextDouble(),
      phase: random.nextDouble() * math.pi * 2,
      radius: 1.5 + random.nextDouble() * 1.5,
    );
  });

  _NetworkPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = _nodes.map((n) => n.positionAt(t, size)).toList();

    const maxDistance = 150.0;
    final linePaint = Paint()..strokeWidth = 1;

    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final distance = (positions[i] - positions[j]).distance;
        if (distance < maxDistance) {
          final opacity = (1 - distance / maxDistance) * 0.35;
          linePaint.color = Colors.blueAccent.withValues(alpha: opacity);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    final nodePaint = Paint()..color = Colors.lightBlueAccent.withValues(alpha: 0.7);
    for (var i = 0; i < positions.length; i++) {
      canvas.drawCircle(positions[i], _nodes[i].radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => oldDelegate.t != t;
}
