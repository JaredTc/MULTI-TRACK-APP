import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/config/app_theme.dart';
import 'package:multitracks/data/track_model.dart'; // Ajusta la ruta si difiere
import 'package:multitracks/providers/session_provider.dart'; // Ajusta la ruta a tu provider

class TracksWidgets extends ConsumerWidget {
  final VoidCallback? onTrackAdded;

  const TracksWidgets({super.key, this.onTrackAdded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el estado global del reproductor
    final sessionState = ref.watch(sessionProvider);
    final sessionNotifier = ref.read(sessionProvider.notifier);

    return Container(
      height: 480,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Botones de Acción Superiores
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => sessionNotifier.clearAllSolos(),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'CLEAR ALL SOLOS',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => sessionNotifier.clearAllMutes(),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.btnRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'CLEAR ALL MUTES',
                    style: TextStyle(
                      color: AppTheme.redTitle,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Área de Mezcla (Scroll Horizontal)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mapeo dinámico leyendo desde el provider
                  ...sessionState.tracks.map((track) {
                    return TrackFaderCard(track: track);
                  }),

                  // Botón '+' que llama a la carga desde almacenamiento
                  AddTrackCard(
                    onTap: () async {
                      await sessionNotifier.pickAndAddTracks();
                      if (onTrackAdded != null) {
                        onTrackAdded!();
                      }
                    },
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

class TrackFaderCard extends ConsumerWidget {
  final TrackModel track;

  const TrackFaderCard({super.key, required this.track});

  void _updateVolumeFromOffset(
    double localPositionY,
    double maxHeight,
    WidgetRef ref,
  ) {
    final double newVolume = (1.0 - (localPositionY / maxHeight)).clamp(
      0.0,
      1.0,
    );
    ref.read(sessionProvider.notifier).updateVolume(track.id, newVolume);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionNotifier = ref.read(sessionProvider.notifier);

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Tarjeta del Fader + Relleno + Texto
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = constraints.maxHeight;
                  final currentHeight = maxHeight * track.volume;

                  return GestureDetector(
                    onVerticalDragUpdate: (details) {
                      _updateVolumeFromOffset(
                        details.localPosition.dy,
                        maxHeight,
                        ref,
                      );
                    },
                    onTapDown: (details) {
                      _updateVolumeFromOffset(
                        details.localPosition.dy,
                        maxHeight,
                        ref,
                      );
                    },
                    child: Stack(
                      children: [
                        // Fondo dinámico azul/color asignado que sube y baja
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: currentHeight,
                          child: Container(color: track.color),
                        ),

                        // Nombre de la pista rotado verticalmente
                        Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              track.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),

                        // 1. Riel de fondo
                        Positioned(
                          top: 16,
                          bottom: 16,
                          left: 16,
                          child: Container(
                            width: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // 2. Riel activo
                        Positioned(
                          bottom: 16,
                          left: 16,
                          height: (currentHeight - 16).clamp(
                            0.0,
                            maxHeight - 32.0,
                          ),
                          child: Container(
                            width: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // 3. Perilla del Fader
                        Positioned(
                          left: 9,
                          bottom: (currentHeight - 10).clamp(
                            10.0,
                            maxHeight - 26.0,
                          ),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Botones de Mute (M) y Solo (S)
          Row(
            children: [
              // Botón MUTE
              Expanded(
                child: GestureDetector(
                  onTap: () => sessionNotifier.toggleMute(track.id),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: track.isMuted
                          ? Colors.redAccent
                          : const Color(0xFF28282B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: track.isMuted ? Colors.white : Colors.white24,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botón SOLO
              Expanded(
                child: GestureDetector(
                  onTap: () => sessionNotifier.toggleSolo(track.id),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: track.isSolo
                          ? AppTheme.primaryColor
                          : const Color(0xFF28282B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: track.isSolo ? Colors.black : Colors.white24,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddTrackCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddTrackCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Colors.white24,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashSpace: 4,
          borderRadius: 16,
        ),
        child: Container(
          width: 110,
          height: 320,
          decoration: BoxDecoration(
            color: AppTheme.thirdColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.add, color: Colors.white54, size: 24),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ADD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.borderRadius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}
