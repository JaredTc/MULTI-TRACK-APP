import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/providers/session_meta_provider.dart';
import 'package:multitracks/providers/tracks_mixer_provider.dart';
import 'package:multitracks/services/hive_service.dart';
import 'package:multitracks/widgets/app_bar_sesions.dart';
import 'package:multitracks/widgets/player.dart';
import 'package:multitracks/widgets/tracks_panels.dart';
import 'package:multitracks/widgets/waves_track.dart';

class NewSesionScreen extends ConsumerStatefulWidget {
  final String sessionTitle;
  final String keyNote;
  final int bpm;
  final String sessionId;

  const NewSesionScreen({
    super.key,
    this.sessionTitle = 'NEW SESION',
    this.keyNote = 'C / DO',
    this.bpm = 120,
    this.sessionId = '',
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

    if (widget.sessionId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final sessionData = HiveService.getSession(widget.sessionId);
        if (sessionData != null) {
          // El método orchestrador loadSessionFromMap ahora vive en sessionMetadataProvider
          await ref
              .read(sessionMetadataProvider.notifier)
              .loadSessionFromMap(sessionData);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lectura de variables del loader desde tracksMixerProvider
    final isLoading = ref.watch(tracksMixerProvider.select((s) => s.isLoading));
    final loadingStatus = ref.watch(
      tracksMixerProvider.select((s) => s.loadingStatus),
    );
    final loadingProgress = ref.watch(
      tracksMixerProvider.select((s) => s.loadingProgress),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF14141A),
          appBar: AppBarNav(
            titleController: _titleController,
            initialKeyNote: _currentKeyNote,
            initialBpm: _currentBpm,
            sessionId: widget.sessionId,
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
                    const WaveTrack(),
                    const SizedBox(height: 20),
                    Player(bpm: _currentBpm),
                    const SizedBox(height: 20),
                    const TracksWidgets(),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Loader dinámico consumiendo los estados de tracksMixerProvider
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Card(
                color: const Color(0xFF1E1E2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loadingStatus.isNotEmpty
                            ? loadingStatus
                            : 'Cargando pistas...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: loadingProgress > 0 ? loadingProgress : null,
                            minHeight: 10,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFA8F5A2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(loadingProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
