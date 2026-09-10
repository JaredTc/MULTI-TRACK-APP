import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/providers/session_provider.dart'; // Importa tu provider
import 'package:multitracks/widgets/app_bar_sesions.dart';
import 'package:multitracks/widgets/player.dart';
import 'package:multitracks/widgets/tracks_panels.dart';
import 'package:multitracks/widgets/waves_track.dart';

class NewSesionScreen extends ConsumerStatefulWidget {
  final String sessionTitle;
  final String keyNote;
  final int bpm;

  const NewSesionScreen({
    super.key,
    this.sessionTitle = 'NEW SESION',
    this.keyNote = 'C / DO',
    this.bpm = 120,
  });

  @override
  ConsumerState<NewSesionScreen> createState() => _NewSesionScreenState();
}

class _NewSesionScreenState extends ConsumerState<NewSesionScreen> {
  late TextEditingController _titleController;
  late String _currentKeyNote;
  late int _currentBpm;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sessionTitle);
    _currentKeyNote = widget.keyNote;
    _currentBpm = widget.bpm;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(sessionProvider.select((s) => s.isLoading));
    final hasTracks = ref.watch(
      sessionProvider.select((s) => s.tracks.isNotEmpty),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF14141A),
          appBar: AppBarNav(
            titleController: _titleController,
            initialKeyNote: _currentKeyNote,
            initialBpm: _currentBpm,
            onChanged: (updatedTitle, updatedKey, updatedBpm) {
              setState(() {
                _currentKeyNote = updatedKey;
                _currentBpm = updatedBpm;
              });
            },
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'NEW SESION',
                        hintStyle: TextStyle(color: Colors.white30),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    // Muestra la onda solo si hay pistas
                    if (hasTracks) ...[
                      const WaveTrack(),
                      const SizedBox(height: 20),
                    ],
                    Player(bpm: _currentBpm),
                    const SizedBox(height: 20),
                    const TracksWidgets(),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.8),
            child: GestureDetector(
              onTap: () {}, // No hace nada, pero captura el tap
              child: Center(
                child: Card(
                  color: const Color(
                    0xFF1E1E2C,
                  ), // Fondo de la tarjeta de carga
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Ajusta al contenido
                      children: [
                        // Spinner verde (como tu playhead)
                        CircularProgressIndicator(
                          color: Color(0xFFA8F5A2),
                          strokeWidth: 5,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Cargando Multitracks...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration
                                .none, // Quita subrayado amarillo de debug
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Configurando streaming de audio',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
