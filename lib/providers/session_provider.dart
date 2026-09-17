import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:multitracks/data/sesion_state.dart';
import 'package:multitracks/data/track_model.dart';
import 'package:multitracks/services/hive_service.dart';

class SessionNotifier extends Notifier<SessionState> {
  StreamSubscription<Duration>? _positionSubscription;

  @override
  SessionState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
      for (var track in state.tracks) {
        track.player.dispose();
      }
    });
    return SessionState();
  }

  Future<void> pickAndAddTracks() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true, // Selección múltiple activada
    );

    if (result == null || result.files.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final colors = [
        const Color(0xFF8B0000),
        const Color(0xFF2E8B57),
        const Color(0xFF4B0082),
        const Color(0xFFD2691E),
        const Color(0xFF0088FF),
        const Color(0xFFDAA520),
      ];

      List<TrackModel> newTracksList = [...state.tracks];
      Duration maxDuration = state.duration;

      for (var file in result.files) {
        if (file.path == null) continue;

        final filePath = file.path!;
        final fileName = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');

        final player = AudioPlayer();

        final trackDuration = await player.setAudioSource(
          AudioSource.uri(Uri.file(filePath)),
          preload: true,
        );

        final newTrack = TrackModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${newTracksList.length}',
          title: fileName,
          color: colors[newTracksList.length % colors.length],
          filePath: filePath,
          player: player,
        );

        if (newTracksList.isNotEmpty) {
          final currentPos = newTracksList.first.player.position;
          await player.seek(currentPos);
        }

        if (newTracksList.isEmpty) {
          _positionSubscription?.cancel();
          _positionSubscription = player.positionStream.listen((pos) {
            state = state.copyWith(position: pos);
          });
        }

        if ((trackDuration ?? Duration.zero) > maxDuration) {
          maxDuration = trackDuration ?? maxDuration;
        }

        newTracksList.add(newTrack);

        _applyAudioOutput(newTrack);

        if (state.isPlaying) {
          await player.play();
        }
      }

      state = state.copyWith(tracks: newTracksList, duration: maxDuration);
    } catch (e) {
      debugPrint("Error al importar archivos: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> togglePlay() async {
    if (state.tracks.isEmpty) return;

    if (state.isPlaying) {
      await Future.wait(state.tracks.map((t) => t.player.pause()));
      state = state.copyWith(isPlaying: false);
    } else {
      final masterPosition = state.tracks.first.player.position;

      await Future.wait(
        state.tracks.map((t) async {
          await t.player.pause();
          await t.player.seek(masterPosition);
        }),
      );

      await Future.wait(state.tracks.map((t) => t.player.play()));
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> stop() async {
    await Future.wait(
      state.tracks.map((t) async {
        await t.player.pause();
        await t.player.seek(Duration.zero);
      }),
    );
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  // Búsqueda precisa (Seek)
  Future<void> seekTo(double progressNormalized) async {
    if (state.tracks.isEmpty) return;

    final targetMs = (state.duration.inMilliseconds * progressNormalized)
        .toInt();
    final targetDuration = Duration(milliseconds: targetMs);
    final isCurrentlyPlaying = state.isPlaying;

    if (isCurrentlyPlaying) {
      await Future.wait(state.tracks.map((t) => t.player.pause()));
    }

    await Future.wait(state.tracks.map((t) => t.player.seek(targetDuration)));
    state = state.copyWith(position: targetDuration);

    if (isCurrentlyPlaying) {
      await Future.wait(state.tracks.map((t) => t.player.play()));
    }
  }

  void updateVolume(String trackId, double volume) {
    final updatedTracks = state.tracks.map((t) {
      if (t.id == trackId) {
        final updated = t.copyWith(volume: volume);
        _applyAudioOutput(updated);
        return updated;
      }
      return t;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
  }

  void setMasterVolume(double volume) {
    state = state.copyWith(masterVolume: volume);
    for (var track in state.tracks) {
      _applyAudioOutput(track);
    }
  }

  // Mute y Solo
  void toggleMute(String trackId) {
    final updatedTracks = state.tracks.map((t) {
      return t.id == trackId ? t.copyWith(isMuted: !t.isMuted) : t;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
    _recalculateAllAudioOutputs();
  }

  void toggleSolo(String trackId) {
    final updatedTracks = state.tracks.map((t) {
      return t.id == trackId ? t.copyWith(isSolo: !t.isSolo) : t;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
    _recalculateAllAudioOutputs();
  }

  void clearAllMutes() {
    final updatedTracks = state.tracks
        .map((t) => t.copyWith(isMuted: false))
        .toList();
    state = state.copyWith(tracks: updatedTracks);
    _recalculateAllAudioOutputs();
  }

  void removeAllTracks() {
    for (var track in state.tracks) {
      track.player.dispose();
    }
    _positionSubscription?.cancel();
    state = SessionState();
  }

  void clearAllSolos() {
    final updatedTracks = state.tracks
        .map((t) => t.copyWith(isSolo: false))
        .toList();
    state = state.copyWith(tracks: updatedTracks);
    _recalculateAllAudioOutputs();
  }

  // Reglas de salida de audio
  void _recalculateAllAudioOutputs() {
    for (var track in state.tracks) {
      _applyAudioOutput(track);
    }
  }

  void _applyAudioOutput(TrackModel track) {
    final hasActiveSolo = state.tracks.any((t) => t.isSolo);

    if (hasActiveSolo) {
      final targetVolume = track.isSolo
          ? (track.volume * state.masterVolume)
          : 0.0;
      track.player.setVolume(targetVolume);
    } else {
      final targetVolume = track.isMuted
          ? 0.0
          : (track.volume * state.masterVolume);
      track.player.setVolume(targetVolume);
    }
  }

  Future<bool> saveCurrentSession({
    required String sessionId,
    required String title,
    required String keyNote,
    required int bpm,
  }) async {
    if (state.tracks.isEmpty) return false;

    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final idToSave = sessionId.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : sessionId;

      final sessionMap = {
        'id': idToSave,
        'title': title,
        'keyNote': keyNote,
        'bpm': bpm,
        'masterVolume': state.masterVolume,
        'tracks': state.tracks.map((t) => t.toMap()).toList(),
      };

      // Guardado rápido directamente en la caja de Hive
      await HiveService.saveSession(sessionMap);
      return true;
    } catch (e) {
      debugPrint("Error al guardar la sesión en Hive: $e");
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Método para cargar una sesión leída de Hive al reproductor
  Future<void> loadSessionFromMap(Map<String, dynamic> sessionData) async {
    // 1. Limpiar la sesión previa de audio
    for (var track in state.tracks) {
      await track.player.stop();
      await track.player.dispose();
    }
    _positionSubscription?.cancel();

    state = SessionState(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 100));

    List<TrackModel> loadedTracks = [];
    Duration maxDuration = Duration.zero;

    final rawTracks = sessionData['tracks'] as List<dynamic>;

    for (var trackMap in rawTracks) {
      final map = Map<String, dynamic>.from(trackMap);
      final filePath = map['filePath'] as String;

      final player = AudioPlayer();

      try {
        // Configuramos la fuente en streaming local (sin volcar a RAM)
        final trackDuration = await player.setAudioSource(
          AudioSource.uri(Uri.file(filePath)),
          preload: false,
        );

        final track = TrackModel.fromMap(map, player);

        if ((trackDuration ?? Duration.zero) > maxDuration) {
          maxDuration = trackDuration ?? maxDuration;
        }

        loadedTracks.add(track);
        _applyAudioOutput(track);
      } catch (e) {
        debugPrint("Error cargando archivo ($filePath): $e");
        await player.dispose();
      }
    }

    if (loadedTracks.isNotEmpty) {
      _positionSubscription = loadedTracks.first.player.positionStream.listen((
        pos,
      ) {
        state = state.copyWith(position: pos);
      });
    }

    state = state.copyWith(
      tracks: loadedTracks,
      duration: maxDuration,
      masterVolume: (sessionData['masterVolume'] as num?)?.toDouble() ?? 1.0,
      isLoading: false,
    );
  }

  // Método indispensable para vaciar todo antes de crear una nueva sesión
  Future<void> resetSession() async {
    // 1. Detener y liberar memoria de todos los reproductores existentes
    _positionSubscription?.cancel();
    for (var track in state.tracks) {
      try {
        await track.player.stop();
        await track.player.dispose();
      } catch (e) {
        debugPrint("Error liberando reproductor: $e");
      }
    }

    // 2. Regresar el estado a los valores iniciales por defecto (sin tracks)
    state = SessionState();
  }

  // Método opcional para actualizar título, nota y BPM en el estado global
  void updateMetadata({String? title, String? keyNote, int? bpm}) {
    state = state.copyWith(
      title: title ?? state.title,
      keyNote: keyNote ?? state.keyNote,
      bpm: bpm ?? state.bpm,
    );
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
