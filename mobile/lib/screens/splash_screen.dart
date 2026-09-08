import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _badgesSlideAnimation;
  late Animation<double> _textSlideAnimation;

  // Interactive 3D drag tilt offsets
  double _dragX = 0.0;
  double _dragY = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Entrance choreography controller (1400ms)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _badgesSlideAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.4, 0.95, curve: Curves.easeOutCubic),
    );

    _textSlideAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOutQuart),
    );

    // 2. Continuous floating 3D pendulum oscillation (3200ms loop)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // 3. Shimmer laser glow sweep controller (2200ms loop)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _introController.forward();

    // Auto-navigate to Onboarding after splash show duration (3.2s)
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const OnboardingScreen(),
            transitionsBuilder: (_, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF031D16),
      body: Stack(
        children: [
          // 1. Dynamic Ambient Gradient & Radial Lights
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFF0C5643), // Vibrant Deep Teal Glow
                    Color(0xFF063327), // Forest Core
                    Color(0xFF021711), // Midnight Base
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. Floating 3D Ambient Particle Stars / Bokeh
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticleFieldPainter(
                    progress: _floatController.value,
                  ),
                );
              },
            ),
          ),

          // 3. Subtle Ambient Light Cones
          Positioned(
            top: size.height * 0.15,
            left: size.width * 0.5 - 160,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.18),
                    const Color(0xFF047857).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. Main 3D Stage & Interactive Content
          SafeArea(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _dragX = (_dragX + details.delta.dx * 0.005).clamp(-0.4, 0.4);
                  _dragY = (_dragY - details.delta.dy * 0.005).clamp(-0.4, 0.4);
                });
              },
              onPanEnd: (_) {
                setState(() {
                  _dragX = 0.0;
                  _dragY = 0.0;
                });
              },
              child: Container(
                color: Colors.transparent, // Capture gestures across full screen
                width: double.infinity,
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // 3D Isometric Floating Centerpiece Stage
                    AnimatedBuilder(
                      animation: Listenable.merge([_introController, _floatController]),
                      builder: (context, _) {
                        final floatVal = _floatController.value;
                        // Smooth sinusoidal 3D rotations
                        final autoRotX = math.sin(floatVal * math.pi * 2) * 0.07;
                        final autoRotY = math.cos(floatVal * math.pi * 2) * 0.09;
                        final autoTransZ = math.sin(floatVal * math.pi * 2) * 12.0;

                        final rotX = autoRotX + _dragY;
                        final rotY = autoRotY + _dragX;

                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0014) // True 3D perspective depth
                            ..rotateX(rotX)
                            ..rotateY(rotY)
                            ..translate(0.0, autoTransZ, 0.0)
                            ..scale(_scaleAnimation.value),
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: _build3DStage(size),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 1),

                    // Brand Identity & Typography
                    AnimatedBuilder(
                      animation: _introController,
                      builder: (context, _) {
                        final slide = (1.0 - _textSlideAnimation.value) * 30.0;
                        return Transform.translate(
                          offset: Offset(0, slide),
                          child: Opacity(
                            opacity: _textSlideAnimation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Brand Title with 3D Layered Lighting
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'FINISH',
                                      style: AppTypography.displayLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 6.0,
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFF10B981).withOpacity(0.5),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                          const Shadow(
                                            color: Colors.black54,
                                            blurRadius: 10,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Golden 3D dot
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFF59E0B).withOpacity(0.8),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Tagline with frosted pill container
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Text(
                                    'Small jobs. Real people. Done.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: const Color(0xFFD1FAE5),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Ethiopia localized badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF34D399)),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Ethiopia's #1 On-Demand Task Marketplace",
                                      style: AppTypography.labelMedium.copyWith(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Modern Glowing Laser Shimmer Loader Bar
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return Container(
                          width: 140,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: (_shimmerController.value * 180) - 50,
                                  top: 0,
                                  bottom: 0,
                                  width: 60,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFF34D399),
                                          const Color(0xFF6EE7B7),
                                          Colors.white,
                                          const Color(0xFF34D399),
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Multi-layered 3D Centerpiece with Floating Spatial Micro-Badges
  Widget _build3DStage(Size screenSize) {
    return SizedBox(
      width: 280,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Deep 3D Cast Shadow on Floor
          Positioned(
            bottom: 10,
            child: Container(
              width: 140,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(70, 15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.65),
                    blurRadius: 28,
                    spreadRadius: 8,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: const Color(0xFF047857).withOpacity(0.35),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // 2. Outer 3D Energy Halo Ring
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),

          // 3. Central 3D Embossed Plinth Tile
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF15803D), // High-sheen emerald top
                  Color(0xFF047857), // Mid teal
                  Color(0xFF064E3B), // Deep emerald base
                  Color(0xFF022C22), // Bottom shadow
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
              ),
              boxShadow: [
                // Metallic rim highlight
                BoxShadow(
                  color: Colors.white.withOpacity(0.35),
                  blurRadius: 0,
                  offset: const Offset(-1.5, -1.5),
                ),
                // Deep volumetric 3D extruded drop shadow
                BoxShadow(
                  color: const Color(0xFF011A13).withOpacity(0.85),
                  blurRadius: 20,
                  offset: const Offset(0, 16),
                ),
                // Emerald neon bloom
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner Glass Highlight Ring
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                      width: 1.5,
                    ),
                  ),
                ),

                // 3D Metallic Finish Checkmark & Bolt Emblem
                Transform.scale(
                  scale: 1.05,
                  child: CustomPaint(
                    size: const Size(64, 64),
                    painter: _Emblem3DPainter(),
                  ),
                ),
              ],
            ),
          ),

          // 4. Floating 3D Spatial Badge 1 (Top-Left: "⚡ Instant Match")
          Positioned(
            top: 15,
            left: 0,
            child: AnimatedBuilder(
              animation: _badgesSlideAnimation,
              builder: (context, child) {
                final offset = (1.0 - _badgesSlideAnimation.value) * 35.0;
                return Transform.translate(
                  offset: Offset(-offset, -offset),
                  child: child,
                );
              },
              child: _buildFloating3DPill(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFFBBF24), // Amber bolt
                text: 'Instant Match',
                textColor: const Color(0xFFFDFBF7),
                bgGradient: const [Color(0xFF064E3B), Color(0xFF022C22)],
                borderColor: const Color(0xFF34D399).withOpacity(0.4),
                elevationZ: 25,
              ),
            ),
          ),

          // 5. Floating 3D Spatial Badge 2 (Top-Right: "🛡️ Escrow Secure")
          Positioned(
            top: 25,
            right: 0,
            child: AnimatedBuilder(
              animation: _badgesSlideAnimation,
              builder: (context, child) {
                final offset = (1.0 - _badgesSlideAnimation.value) * 35.0;
                return Transform.translate(
                  offset: Offset(offset, -offset),
                  child: child,
                );
              },
              child: _buildFloating3DPill(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF34D399), // Mint Shield
                text: '100% Escrow',
                textColor: const Color(0xFFFDFBF7),
                bgGradient: const [Color(0xFF065F46), Color(0xFF022C22)],
                borderColor: const Color(0xFF6EE7B7).withOpacity(0.4),
                elevationZ: 30,
              ),
            ),
          ),

          // 6. Floating 3D Spatial Badge 3 (Bottom-Right: "🇪🇹 Telebirr / CBE")
          Positioned(
            bottom: 25,
            right: 15,
            child: AnimatedBuilder(
              animation: _badgesSlideAnimation,
              builder: (context, child) {
                final offset = (1.0 - _badgesSlideAnimation.value) * 30.0;
                return Transform.translate(
                  offset: Offset(offset, offset),
                  child: child,
                );
              },
              child: _buildFloating3DPill(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF60A5FA), // Blue wallet
                text: 'Telebirr · CBE',
                textColor: const Color(0xFFFDFBF7),
                bgGradient: const [Color(0xFF044E3B), Color(0xFF022019)],
                borderColor: const Color(0xFF60A5FA).withOpacity(0.4),
                elevationZ: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build 3D floating pill badges with glassmorphic depth
  Widget _buildFloating3DPill({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    required List<Color> bgGradient,
    required Color borderColor,
    required double elevationZ,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient,
        ),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// 3D Custom Painter for the Faceted Checkmark & Insignia
class _Emblem3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Checkmark geometric points
    final pLeft = Offset(w * 0.18, h * 0.48);
    final pBottom = Offset(w * 0.42, h * 0.78);
    final pTopRight = Offset(w * 0.86, h * 0.24);
    final pTopCorner = Offset(w * 0.86, h * 0.38);
    final pInnerBottom = Offset(w * 0.43, h * 0.62);
    final pInnerLeft = Offset(w * 0.28, h * 0.48);

    // 1. Extruded Depth Bevel (Under-facet)
    final depthPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF034A38), Color(0xFF01241C)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final depthPath = Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pBottom.dx, pBottom.dy + 6)
      ..lineTo(pLeft.dx, pLeft.dy + 6)
      ..close();
    canvas.drawPath(depthPath, depthPaint);

    final depthPathRight = Path()
      ..moveTo(pBottom.dx, pBottom.dy)
      ..lineTo(pTopCorner.dx, pTopCorner.dy)
      ..lineTo(pTopCorner.dx, pTopCorner.dy + 6)
      ..lineTo(pBottom.dx, pBottom.dy + 6)
      ..close();
    canvas.drawPath(depthPathRight, depthPaint);

    // 2. Left Stem Facet (Deep Emerald)
    final leftFacetPath = Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pInnerBottom.dx, pInnerBottom.dy)
      ..lineTo(pInnerLeft.dx, pInnerLeft.dy)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(leftFacetPath, leftPaint);

    // 3. Right Wing Facet (Vibrant Mint with Electric Sheen)
    final rightFacetPath = Path()
      ..moveTo(pInnerBottom.dx, pInnerBottom.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pTopCorner.dx, pTopCorner.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF10B981), Color(0xFF6EE7B7), Color(0xFFA7F3D0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(rightFacetPath, rightPaint);

    // 4. Highlight Edge Lines (Specular Shine)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final outlinePath = Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pTopCorner.dx, pTopCorner.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pInnerBottom.dx, pInnerBottom.dy)
      ..lineTo(pInnerLeft.dx, pInnerLeft.dy)
      ..close();
    canvas.drawPath(outlinePath, linePaint);

    // 5. Specular Gleams at key apex points
    final gleamPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(pTopRight, 3.2, gleamPaint);
    canvas.drawCircle(pBottom, 2.5, gleamPaint);

    // 6. Top Golden Spark Star
    final starCenter = Offset(w * 0.92, h * 0.16);
    final starPaint = Paint()..color = const Color(0xFFFBBF24);
    final starPath = Path()
      ..moveTo(starCenter.dx, starCenter.dy - 6)
      ..lineTo(starCenter.dx + 4.5, starCenter.dy)
      ..lineTo(starCenter.dx, starCenter.dy + 6)
      ..lineTo(starCenter.dx - 4.5, starCenter.dy)
      ..close();
    canvas.drawPath(starPath, starPaint);
    canvas.drawCircle(starCenter, 1.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Particle field background for subtle depth
class _ParticleFieldPainter extends CustomPainter {
  final double progress;

  _ParticleFieldPainter({required this.progress});

  static final List<math.Point<double>> _staticParticles = List.generate(24, (i) {
    final rand = math.Random(i * 997);
    return math.Point(rand.nextDouble(), rand.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _staticParticles.length; i++) {
      final p = _staticParticles[i];
      final speed = (i % 3 + 1) * 0.15;
      final yOffset = (p.y + progress * speed) % 1.0;
      final x = p.x * size.width;
      final y = yOffset * size.height;

      final radius = (i % 3 == 0) ? 2.2 : (i % 2 == 0 ? 1.4 : 0.8);
      final alpha = (0.2 + 0.4 * math.sin((progress + i) * math.pi)).clamp(0.08, 0.55);

      paint.color = const Color(0xFF34D399).withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
