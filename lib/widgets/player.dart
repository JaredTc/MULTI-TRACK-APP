// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:multitracks/config/app_theme.dart';
// import 'package:multitracks/providers/soloud_session_provider.dart';
// // import 'package:multitracks/providers/session_provider.dart'; // Ajusta la ruta a tu provider

// class Player extends ConsumerWidget {
//   final int bpm;

//   const Player({Key? key, required this.bpm}) : super(key: key);

//   // Formateador dinámico para transformar Duration en cadena "mm:ss"
//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Escuchar el estado global y notificador del reproductor
//     // final sessionState = ref.watch(sessionProvider);
//     // final sessionNotifier = ref.read(sessionProvider.notifier);
//     // Lectura de estado
//     final sessionState = ref.watch(soLoudSessionProvider);

//     // Invocación de acciones
//     final sessionNotifier = ref.read(soLoudSessionProvider.notifier);
//     return Container(
//       height: 100,
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppTheme.secondaryColor,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           // A. BOTONES IZQUIERDA (ANCHO FIJO)
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Reiniciar al inicio (0:00)
//               _buildTransportButton(
//                 Icons.skip_previous,
//                 48,
//                 AppTheme.thirdColor,
//                 onPressed: () => sessionNotifier.seekTo(0.0),
//               ),
//               const SizedBox(width: 8),

//               // Detener (Stop)
//               _buildTransportButton(
//                 Icons.stop,
//                 52,
//                 AppTheme.thirdColor,
//                 onPressed: () => sessionNotifier.stop(),
//               ),
//               const SizedBox(width: 8),

//               // Play / Pause Dinámico
//               _buildTransportButton(
//                 sessionState.isPlaying ? Icons.pause : Icons.play_arrow,
//                 60,
//                 AppTheme.primaryColor,
//                 iconColor: Colors.black,
//                 iconSize: 36,
//                 onPressed: () => sessionNotifier.togglePlay(),
//               ),
//               const SizedBox(width: 8),

//               // Replay / Rebobinar
//               _buildTransportButton(
//                 Icons.replay_outlined,
//                 52,
//                 AppTheme.thirdColor,
//                 onPressed: () => sessionNotifier.seekTo(0.0),
//               ),
//               const SizedBox(width: 8),

//               // Ir al final
//               _buildTransportButton(
//                 Icons.skip_next,
//                 48,
//                 AppTheme.thirdColor,
//                 onPressed: () => sessionNotifier.seekTo(1.0),
//               ),
//             ],
//           ),

//           // Divisor Vertical
//           Container(
//             width: 1,
//             height: 40,
//             color: Colors.white24,
//             margin: const EdgeInsets.symmetric(horizontal: 20),
//           ),

//           // B. CENTRO EXPANDIDO (Sincronizado con la duración del Mix)
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Tiempo Transcurrido Real
//                     Text(
//                       _formatDuration(sessionState.position),
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                       ),
//                     ),
//                     Text(
//                       '$bpm BPM',
//                       style: const TextStyle(
//                         color: AppTheme.primaryColor,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const Text(
//                       '4/4',
//                       style: TextStyle(color: Colors.white70, fontSize: 13),
//                     ),
//                     // Duración Total del Mix (Calculada dinámicamente)
//                     Text(
//                       _formatDuration(sessionState.duration),
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 SliderTheme(
//                   data: SliderThemeData(
//                     trackHeight: 5,
//                     thumbShape: const RoundSliderThumbShape(
//                       enabledThumbRadius: 6,
//                     ),
//                     overlayShape: const RoundSliderOverlayShape(
//                       overlayRadius: 12,
//                     ),
//                     activeTrackColor: AppTheme.primaryColor,
//                     inactiveTrackColor: Colors.white12,
//                     thumbColor: AppTheme.primaryColor,
//                   ),
//                   child: Slider(
//                     value: sessionState.progress,
//                     onChanged: (val) => sessionNotifier.seekTo(val),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(width: 20),

//           // C. DERECHA (VOLUMEN MÁSTER Y PITCH)
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Control de Volumen Máster real
//               _buildMiniVolumeSlider(
//                 Icons.volume_up,
//                 sessionState.masterVolume,
//                 (val) => sessionNotifier.setMasterVolume(val),
//               ),
//               const SizedBox(width: 10),
//               // Control visual de Pitch (Inerte o asignable a futuro)
//               _buildMiniVolumeSlider(Icons.sync, 0.5, (val) {}),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransportButton(
//     IconData icon,
//     double size,
//     Color bgColor, {
//     Color iconColor = Colors.white,
//     double iconSize = 24,
//     VoidCallback? onPressed,
//   }) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: IconButton(
//         padding: EdgeInsets.zero,
//         icon: Icon(icon, color: iconColor, size: iconSize),
//         onPressed: onPressed,
//       ),
//     );
//   }

//   Widget _buildMiniVolumeSlider(
//     IconData icon,
//     double value,
//     ValueChanged<double> onChanged,
//   ) {
//     return Container(
//       width: 140,
//       height: 44,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       decoration: BoxDecoration(
//         color: AppTheme.thirdColor,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.white70, size: 18),
//           Expanded(
//             child: SliderTheme(
//               data: SliderThemeData(
//                 trackHeight: 4,
//                 thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
//                 activeTrackColor: AppTheme.primaryColor,
//                 inactiveTrackColor: Colors.white12,
//                 thumbColor: AppTheme.primaryColor,
//               ),
//               child: Slider(value: value, onChanged: onChanged),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/config/app_theme.dart';
import 'package:multitracks/providers/playback_provider.dart';
import 'package:multitracks/providers/tracks_mixer_provider.dart';

class Player extends ConsumerWidget {
  final int bpm;

  const Player({Key? key, required this.bpm}) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Transporte (Play/Pause, Posición, Seek)
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);

    // 2. Estado del Mezclador (Volumen Máster)
    final masterVolume = ref.watch(
      tracksMixerProvider.select((s) => s.masterVolume),
    );
    final mixerNotifier = ref.read(tracksMixerProvider.notifier);

    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // A. BOTONES IZQUIERDA
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTransportButton(
                Icons.skip_previous,
                48,
                AppTheme.thirdColor,
                onPressed: () => playbackNotifier.seekTo(0.0),
              ),
              const SizedBox(width: 8),
              _buildTransportButton(
                Icons.stop,
                52,
                AppTheme.thirdColor,
                onPressed: () => playbackNotifier.stop(),
              ),
              const SizedBox(width: 8),
              _buildTransportButton(
                playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                60,
                AppTheme.primaryColor,
                iconColor: Colors.black,
                iconSize: 36,
                onPressed: () => playbackNotifier.togglePlay(),
              ),
              const SizedBox(width: 8),
              _buildTransportButton(
                Icons.replay_outlined,
                52,
                AppTheme.thirdColor,
                onPressed: () => playbackNotifier.seekTo(0.0),
              ),
              const SizedBox(width: 8),
              _buildTransportButton(
                Icons.skip_next,
                48,
                AppTheme.thirdColor,
                onPressed: () => playbackNotifier.seekTo(1.0),
              ),
            ],
          ),

          // DIVISOR VERTICAL
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),

          // B. CENTRO EXPANDIDO (CRONÓMETRO Y SLIDER)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(playbackState.position),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$bpm BPM',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '4/4',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      _formatDuration(playbackState.duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppTheme.primaryColor,
                  ),
                  child: Slider(
                    value: playbackState.progress,
                    onChanged: (val) => playbackNotifier.seekTo(val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // C. DERECHA (VOLUMEN MÁSTER VÍA tracksMixerProvider)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniVolumeSlider(
                Icons.volume_up,
                masterVolume,
                (val) => mixerNotifier.setMasterVolume(val),
              ),
              const SizedBox(width: 10),
              _buildMiniVolumeSlider(Icons.sync, 0.5, (val) {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportButton(
    IconData icon,
    double size,
    Color bgColor, {
    Color iconColor = Colors.white,
    double iconSize = 24,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMiniVolumeSlider(
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      width: 140,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.thirdColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: Colors.white12,
                thumbColor: AppTheme.primaryColor,
              ),
              child: Slider(value: value, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }
}
