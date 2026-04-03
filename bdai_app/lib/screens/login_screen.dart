import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bdai/core/app_constants.dart';
import 'package:bdai/screens/home_screen.dart';
import 'package:bdai/widgets/bdai_logo.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BdaiLogoWidget(size: 70),
              const SizedBox(height: 20),
              const Text('বিডিএআই-তে স্বাগতম', style: TextStyle(
                fontFamily: 'HindSiliguri', fontSize: 24, fontWeight: FontWeight.w700,
                color: Color(0xFFE6EDF3),
              )),
              const SizedBox(height: 6),
              const Text('আপনার AI সহকারী', style: TextStyle(
                fontFamily: 'HindSiliguri', fontSize: 14, color: Color(0xFF8B949E),
              )),
              const SizedBox(height: 36),

              // Google sign-in button
              _GoogleBtn(onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(AppConstants.isLoggedInKey, true);
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const HomeScreen(),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                      transitionDuration: const Duration(milliseconds: 350),
                    ),
                  );
                }
              }),

              const SizedBox(height: 16),
              const Text('Demo mode — প্রকৃত লগইন নেই', style: TextStyle(
                fontFamily: 'HindSiliguri', fontSize: 11, color: Color(0xFF484F58),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleBtn extends StatefulWidget {
  const _GoogleBtn({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_GoogleBtn> createState() => _GoogleBtnState();
}

class _GoogleBtnState extends State<_GoogleBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFF1C2333) : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF30363D)),
            boxShadow: _pressed ? [] : [const BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google SVG icon (simplified)
              SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleIconPainter())),
              const SizedBox(width: 12),
              const Text('Google দিয়ে প্রবেশ করুন', style: TextStyle(
                fontFamily: 'HindSiliguri', fontSize: 16, fontWeight: FontWeight.w600,
                color: Color(0xFFE6EDF3),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // Simplified colored circle
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -1.57, 3.14, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 1.57, 1.57, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 3.14, 0.79, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 3.93, 0.79, true, paint);
    paint.color = const Color(0xFF161B22);
    canvas.drawCircle(c, r * 0.45, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
