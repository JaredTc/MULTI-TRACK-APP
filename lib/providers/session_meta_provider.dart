import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:multitracks/data/soloud_track_model.dart';
import 'package:multitracks/services/hive_service.dart';
import 'playback_provider.dart';
import 'tracks_mixer_provider.dart';

class SessionMetadataState {
  final String sessionId;
  final String title;
  final String keyNote;
  final int bpm;
  final String? coverImagePath;

  const SessionMetadataState({
    this.sessionId = '',
    this.title = '',
    this.keyNote = 'C / DO',
    this.bpm = 120,
    this.coverImagePath,
  });

  SessionMetadataState copyWith({
    String? sessionId,
    String? title,
    String? keyNote,
    int? bpm,
    String? coverImagePath,
  }) {
    return SessionMetadataState(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      keyNote: keyNote ?? this.keyNote,
      bpm: bpm ?? this.bpm,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }
}

class SessionMetadataNotifier extends Notifier<SessionMetadataState> {
  @override
  SessionMetadataState build() => const SessionMetadataState();

  void updateMetadata({String? title, String? keyNote, int? bpm}) {
    state = state.copyWith(
      title: title ?? state.title,
      keyNote: keyNote ?? state.keyNote,
      bpm: bpm ?? state.bpm,
    );
  }

  Future<void> loadSessionFromMap(Map<String, dynamic> sessionData) async {
    ref.read(playbackProvider.notifier).resetPlayback();

    try {
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.deinit();
      }
      await SoLoud.instance.init();
    } catch (e) {
      debugPrint("Error al reinicializar el motor SoLoud: $e");
    }

    await ref.read(tracksMixerProvider.notifier).disposeAllTracks();

    final mixerNotifier = ref.read(tracksMixerProvider.notifier);
    mixerNotifier.setLoading(true, 'Iniciando carga...', 0.0);

    List<SoLoudTrackModel> loadedTracks = [];
    Duration maxDuration = Duration.zero;

    final rawTracks = sessionData['tracks'] as List<dynamic>? ?? [];
    final totalFiles = rawTracks.length;

    for (int i = 0; i < rawTracks.length; i++) {
      final map = Map<String, dynamic>.from(rawTracks[i]);
      final filePath = map['filePath'] as String?;

      if (filePath == null || filePath.isEmpty) continue;
      final fileName = filePath.split('/').last;

      mixerNotifier.setLoading(
        true,
        'Cargando $fileName (${i + 1}/$totalFiles)...',
        totalFiles > 0 ? (i + 1) / totalFiles : 0.0,
      );

      try {
        final source = await SoLoud.instance.loadFile(
          filePath,
          mode: LoadMode.disk,
        );

        final trackDuration = SoLoud.instance.getLength(source);
        final track = SoLoudTrackModel.fromMap(map, source);

        if (trackDuration > maxDuration) {
          maxDuration = trackDuration;
        }

        loadedTracks.add(track);
        await Future.delayed(const Duration(milliseconds: 30));
      } catch (e) {
        debugPrint("Error cargando fuente ($filePath): $e");
      }
    }

    final masterVol = (sessionData['masterVolume'] as num?)?.toDouble() ?? 1.0;
    mixerNotifier.setLoadedTracks(loadedTracks, masterVol);
    ref.read(playbackProvider.notifier).updateDuration(maxDuration);

    state = SessionMetadataState(
      sessionId: sessionData['id'] as String? ?? '',
      title: sessionData['title'] as String? ?? '',
      keyNote: sessionData['keyNote'] as String? ?? 'C / DO',
      bpm: (sessionData['bpm'] as num?)?.toInt() ?? 120,
    );

    mixerNotifier.setLoading(false);
  }

  Future<bool> saveCurrentSession({
    required String sessionId,
    required String title,
    required String keyNote,
    required int bpm,
  }) async {
    final mixerState = ref.read(tracksMixerProvider);
    if (mixerState.tracks.isEmpty) return false;

    ref.read(tracksMixerProvider.notifier).setLoading(true);
    try {
      final idToSave = sessionId.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : sessionId;

      final sessionMap = {
        'id': idToSave,
        'title': title,
        'keyNote': keyNote,
        'bpm': bpm,
        'masterVolume': mixerState.masterVolume,
        'tracks': mixerState.tracks.map((t) => t.toMap()).toList(),
      };

      await HiveService.saveSession(sessionMap);
      return true;
    } catch (e) {
      debugPrint("Error guardando sesión: $e");
      return false;
    } finally {
      ref.read(tracksMixerProvider.notifier).setLoading(false);
    }
  }

  Future<void> resetSession() async {
    ref.read(playbackProvider.notifier).resetPlayback();
    await ref.read(tracksMixerProvider.notifier).disposeAllTracks();
    state = const SessionMetadataState();
  }

  void setCoverImage(String? path) {
    state = state.copyWith(coverImagePath: path);
  }
}

final sessionMetadataProvider =
    NotifierProvider<SessionMetadataNotifier, SessionMetadataState>(
      SessionMetadataNotifier.new,
    );
