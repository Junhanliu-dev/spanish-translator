import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';

/// Decorative overlay for the camera capture screen.
///
/// Shows a guide frame with corner accents, a tip banner, and a subtle
/// breathing scale animation.
class CameraViewfinderOverlay extends StatelessWidget {
  const CameraViewfinderOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final frameWidth = size.width * 0.85;
    final frameHeight = size.height * 0.55;

    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Guide frame with corner accents and breathing animation.
            SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: CustomPaint(
                painter: _ViewfinderPainter(),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.005, 1.005),
                  duration: 2000.ms,
                ),
            const SizedBox(height: AppSpacing.lg),
            // Tip banner.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Position the menu within the frame',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw main border.
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, borderPaint);

    // Draw corner accents.
    const cornerLen = 20.0;

    // Top-left.
    canvas.drawLine(
      const Offset(0, cornerLen),
      Offset.zero,
      cornerPaint,
    );
    canvas.drawLine(
      Offset.zero,
      const Offset(cornerLen, 0),
      cornerPaint,
    );

    // Top-right.
    canvas.drawLine(
      Offset(size.width - cornerLen, 0),
      Offset(size.width, 0),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLen),
      cornerPaint,
    );

    // Bottom-left.
    canvas.drawLine(
      Offset(0, size.height - cornerLen),
      Offset(0, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLen, size.height),
      cornerPaint,
    );

    // Bottom-right.
    canvas.drawLine(
      Offset(size.width - cornerLen, size.height),
      Offset(size.width, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
