import 'package:flutter/material.dart';

/// BDAi brand logo widget — used everywhere
class BdaiLogoWidget extends StatelessWidget {
  const BdaiLogoWidget({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF00C896), Color(0xFF0070F3)],
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF00C896).withValues(alpha: 0.35), blurRadius: size * 0.4, offset: Offset(0, size * 0.1))],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.58, size * 0.58),
          painter: _BoltPainter(),
        ),
      ),
    );
  }
}

class _BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Lightning bolt shape
    path.moveTo(size.width * 0.62, 0);
    path.lineTo(size.width * 0.18, size.height * 0.52);
    path.lineTo(size.width * 0.46, size.height * 0.52);
    path.lineTo(size.width * 0.38, size.height);
    path.lineTo(size.width * 0.82, size.height * 0.48);
    path.lineTo(size.width * 0.54, size.height * 0.48);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
