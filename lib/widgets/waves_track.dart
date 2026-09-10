import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/config/app_theme.dart';
import 'package:multitracks/providers/session_provider.dart';

class WaveTrack extends ConsumerWidget {
  const WaveTrack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(sessionProvider.select((s) => s.progress));
    final notifier = ref.read(sessionProvider.notifier);

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              final newProgress =
                  (details.localPosition.dx / constraints.maxWidth).clamp(
                    0.0,
                    1.0,
                  );
              notifier.seekTo(newProgress);
            },
            onHorizontalDragUpdate: (details) {
              final newProgress =
                  (details.localPosition.dx / constraints.maxWidth).clamp(
                    0.0,
                    1.0,
                  );
              notifier.seekTo(newProgress);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: WaveformPainter(
                progress: progress,
                playheadColor: const Color(0xFFA8F5A2),
                shadeColor: const Color(
                  0xFF0088FF,
                ).withOpacity(0.20), // Azul tenue
              ),
            ),
          );
        },
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final Color playheadColor;
  final Color shadeColor;

  WaveformPainter({
    required this.progress,
    required this.playheadColor,
    required this.shadeColor,
  });

  final List<double> sampleHeights = const [
    0.2,
    0.3,
    0.45,
    0.6,
    0.75,
    0.85,
    0.9,
    0.95,
    0.9,
    0.7,
    0.4,
    0.5,
    0.75,
    0.9,
    0.95,
    0.9,
    0.8,
    0.65,
    0.8,
    0.9,
    0.95,
    0.9,
    0.75,
    0.5,
    0.3,
    0.45,
    0.7,
    0.85,
    0.95,
    0.8,
    0.6,
    0.4,
    0.3,
    0.5,
    0.7,
    0.85,
    0.9,
    0.8,
    0.6,
    0.4,
    0.3,
    0.5,
    0.75,
    0.9,
    0.95,
    0.85,
    0.7,
    0.5,
    0.3,
    0.4,
    0.6,
    0.8,
    0.9,
    0.85,
    0.7,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double playheadX = size.width * progress;

    // 1. DIBUJAR EL RECTÁNGULO DE SOMBREADO
    if (playheadX > 0) {
      final shadePaint = Paint()
        ..color = shadeColor
        ..style = PaintingStyle.fill;

      final shadeRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, playheadX, size.height),
        topLeft: const Radius.circular(8),
        bottomLeft: const Radius.circular(8),
      );

      canvas.drawRRect(shadeRect, shadePaint);
    }

    final double totalBars = sampleHeights.length.toDouble();
    final double spacing = 3.0;
    final double barWidth = (size.width - (totalBars * spacing)) / totalBars;

    // 2. DIBUJAR BARRAS DE LA ONDA (Estilo único e idéntico para todas)
    final barPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.5;

    for (int i = 0; i < sampleHeights.length; i++) {
      final double x = i * (barWidth + spacing) + barWidth / 2;
      final double barHeight = size.height * sampleHeights[i];
      final double top = (size.height - barHeight) / 2;
      final double bottom = top + barHeight;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), barPaint);
    }

    // 3. DIBUJAR LÍNEA VERDE DE REPRODUCCIÓN (Playhead)
    final playheadPaint = Paint()
      ..color = playheadColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );

    final circlePaint = Paint()
      ..color = playheadColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(playheadX, 0), 4.0, circlePaint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shadeColor != shadeColor ||
        oldDelegate.playheadColor != playheadColor;
  }
}
