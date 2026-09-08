import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color circleColor;
  final Color checkColor;
  final Duration duration;

  const AnimatedCheckmark({
    super.key,
    this.size = 80.0,
    this.circleColor = AppColors.primary,
    this.checkColor = Colors.white,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CheckmarkPainter(
              progress: _checkAnimation.value,
              circleColor: widget.circleColor,
              checkColor: widget.checkColor,
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color circleColor;
  final Color checkColor;

  _CheckmarkPainter({
    required this.progress,
    required this.circleColor,
    required this.checkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    if (progress <= 0) return;

    // Draw Checkmark
    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.72, size.height * 0.36);

    path.moveTo(p1.dx, p1.dy);

    if (progress < 0.4) {
      final subP = progress / 0.4;
      final currentX = p1.dx + (p2.dx - p1.dx) * subP;
      final currentY = p1.dy + (p2.dy - p1.dy) * subP;
      path.lineTo(currentX, currentY);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final subP = (progress - 0.4) / 0.6;
      final currentX = p2.dx + (p3.dx - p2.dx) * subP;
      final currentY = p2.dy + (p3.dy - p2.dy) * subP;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
