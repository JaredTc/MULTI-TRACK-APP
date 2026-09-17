import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/config/app_theme.dart';
import 'package:multitracks/providers/playback_provider.dart';
import 'package:multitracks/providers/tracks_mixer_provider.dart';

class WaveTrack extends ConsumerWidget {
  const WaveTrack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Verificar si existen pistas activas en el mezclador
    final hasTracks = ref.watch(
      tracksMixerProvider.select((s) => s.tracks.isNotEmpty),
    );

    // Si la lista de pistas está vacía, no dibuja nada
    if (!hasTracks) {
      return const SizedBox.shrink();
    }

    // 2. Escuchar únicamente el progreso de reproducción
    final rawProgress = ref.watch(playbackProvider.select((s) => s.progress));

    final progress = (rawProgress.isNaN || rawProgress.isInfinite)
        ? 0.0
        : rawProgress.clamp(0.0, 1.0);

    // 3. Notifier para ejecutar gestos de seek
    final playbackNotifier = ref.read(playbackProvider.notifier);

    return Container(
      height: 100,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              playbackNotifier.seekTo(newProgress);
            },
            onHorizontalDragUpdate: (details) {
              final newProgress =
                  (details.localPosition.dx / constraints.maxWidth).clamp(
                    0.0,
                    1.0,
                  );
              playbackNotifier.seekTo(newProgress);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: DynamicWaveformPainter(
                progress: progress,
                playheadColor: const Color(0xFFA8F5A2),
                shadeColor: const Color(0xFF0088FF).withOpacity(0.20),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DynamicWaveformPainter extends CustomPainter {
  final double progress;
  final Color playheadColor;
  final Color shadeColor;

  DynamicWaveformPainter({
    required this.progress,
    required this.playheadColor,
    required this.shadeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double playheadX = size.width * progress;

    // 1. DIBUJAR SOMBRA DE PROGRESO
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

    // 2. CÁLCULO DINÁMICO DE BARRAS
    const double barWidth = 3.5;
    const double spacing = 2.5;
    final int totalBars = (size.width / (barWidth + spacing)).floor();

    final barPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final Random random = Random(42);

    for (int i = 0; i < totalBars; i++) {
      final double x = i * (barWidth + spacing) + (barWidth / 2);
      final double heightFactor = 0.15 + (random.nextDouble() * 0.75);
      final double barHeight = size.height * heightFactor;
      final double top = (size.height - barHeight) / 2;
      final double bottom = top + barHeight;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), barPaint);
    }

    // 3. DIBUJAR PLAYHEAD
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

    canvas.drawCircle(Offset(playheadX, 0), 4.5, circlePaint);
  }

  @override
  bool shouldRepaint(covariant DynamicWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shadeColor != shadeColor ||
        oldDelegate.playheadColor != playheadColor;
  }
}
