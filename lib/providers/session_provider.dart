import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:multitracks/data/track_model.dart';

class SessionState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<TrackModel> tracks;
  final double masterVolume;
  final bool isLoading;

  SessionState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.tracks = const [],
    this.masterVolume = 1.0,
    this.isLoading = false,
  });

  double get progress => duration.inMilliseconds == 0
      ? 0.0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  SessionState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<TrackModel>? tracks,
    double? masterVolume,
    bool? isLoading,
  }) {
    return SessionState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      tracks: tracks ?? this.tracks,
      masterVolume: masterVolume ?? this.masterVolume,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

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
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
