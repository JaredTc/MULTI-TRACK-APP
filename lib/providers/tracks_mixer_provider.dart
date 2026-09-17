// TODO Implement this library.
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:multitracks/config/app_config.dart';
import 'package:multitracks/data/soloud_track_model.dart';
import 'package:multitracks/providers/session_meta_provider.dart';
import 'playback_provider.dart';

class TracksMixerState {
  final List<SoLoudTrackModel> tracks;
  final double masterVolume;
  final bool isLoading;
  final String loadingStatus;
  final double loadingProgress;

  const TracksMixerState({
    this.tracks = const [],
    this.masterVolume = 1.0,
    this.isLoading = false,
    this.loadingStatus = '',
    this.loadingProgress = 0.0,
  });

  TracksMixerState copyWith({
    List<SoLoudTrackModel>? tracks,
    double? masterVolume,
    bool? isLoading,
    String? loadingStatus,
    double? loadingProgress,
  }) {
    return TracksMixerState(
      tracks: tracks ?? this.tracks,
      masterVolume: masterVolume ?? this.masterVolume,
      isLoading: isLoading ?? this.isLoading,
      loadingStatus: loadingStatus ?? this.loadingStatus,
      loadingProgress: loadingProgress ?? this.loadingProgress,
    );
  }
}

class TracksMixerNotifier extends Notifier<TracksMixerState> {
  @override
  TracksMixerState build() {
    _initEngine();
    ref.onDispose(() => disposeAllTracks());
    return const TracksMixerState();
  }

  Future<void> _initEngine() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init();
      SoLoud.instance.setMaxActiveVoiceCount(64);
    }
  }

  Future<void> pickAndAddTracks() async {
    final colors = AppConfig.trackColors;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    final existingPaths = state.tracks.map((t) => t.filePath).toSet();
    final newFiles = result.files.where((file) {
      return file.path != null && !existingPaths.contains(file.path);
    }).toList();

    if (newFiles.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      loadingStatus: 'Iniciando carga...',
      loadingProgress: 0.0,
    );

    final List<SoLoudTrackModel> newTracks = [];
    Duration maxDuration = ref.read(playbackProvider).duration;

    try {
      final totalFiles = newFiles.length;

      for (int i = 0; i < totalFiles; i++) {
        final file = newFiles[i];
        final filePath = file.path!;
        final fullName = file.name;
        final fileName = fullName.replaceAll(RegExp(r'\.[^.]+$'), '');

        state = state.copyWith(
          loadingStatus: 'Cargando $fullName (${i + 1}/$totalFiles)...',
          loadingProgress: (i + 1) / totalFiles,
        );

        try {
          final source = await SoLoud.instance.loadFile(
            filePath,
            mode: LoadMode.disk,
          );

          final trackDuration = SoLoud.instance.getLength(source);
          if (trackDuration > maxDuration) {
            maxDuration = trackDuration;
          }

          final colorIndex =
              (state.tracks.length + newTracks.length) % colors.length;

          final newTrack = SoLoudTrackModel(
            id: '${DateTime.now().microsecondsSinceEpoch}_$i',
            title: fileName,
            color: colors[colorIndex],
            filePath: filePath,
            soundSource: source,
          );

          newTracks.add(newTrack);
        } catch (fileError) {
          debugPrint("Error cargando archivo ($fileName): $fileError");
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (newTracks.isNotEmpty) {
        state = state.copyWith(tracks: [...state.tracks, ...newTracks]);
        ref.read(playbackProvider.notifier).updateDuration(maxDuration);
      }
    } finally {
      state = state.copyWith(
        isLoading: false,
        loadingStatus: '',
        loadingProgress: 0.0,
      );
    }
  }

  Future<List<SoLoudTrackModel>> ensureVoiceHandles() async {
    final List<SoLoudTrackModel> updatedTracks = [];

    for (var track in state.tracks) {
      SoundHandle? h = track.handle;
      if (h == null || h.id == 0 || !SoLoud.instance.getIsValidVoiceHandle(h)) {
        h = await SoLoud.instance.play(track.soundSource, paused: true);
      }
      updatedTracks.add(track.copyWith(handle: h));
    }

    state = state.copyWith(tracks: updatedTracks);
    return updatedTracks;
  }

  void updateVolume(String trackId, double volume) {
    final updatedTracks = state.tracks.map((t) {
      if (t.id == trackId) {
        final updated = t.copyWith(volume: volume);
        applyAudioOutputForTrack(updated);
        return updated;
      }
      return t;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
  }

  void toggleMute(String trackId) {
    final updatedTracks = state.tracks.map((t) {
      return t.id == trackId ? t.copyWith(isMuted: !t.isMuted) : t;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
    recalculateAllAudioOutputs();
  }

  void toggleSolo(String trackId) {
    final updatedTracks = state.tracks.map((t) {
      return t.id == trackId ? t.copyWith(isSolo: !t.isSolo) : t;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
    recalculateAllAudioOutputs();
  }

  void clearAllMutes() {
    state = state.copyWith(
      tracks: state.tracks.map((t) => t.copyWith(isMuted: false)).toList(),
    );
    recalculateAllAudioOutputs();
  }

  void clearAllSolos() {
    state = state.copyWith(
      tracks: state.tracks.map((t) => t.copyWith(isSolo: false)).toList(),
    );
    recalculateAllAudioOutputs();
  }

  void setMasterVolume(double volume) {
    state = state.copyWith(masterVolume: volume);
    recalculateAllAudioOutputs();
  }

  void setTrackPan(String trackId, double panValue) {
    final clampedPan = panValue.clamp(-1.0, 1.0);
    final updatedTracks = state.tracks.map((track) {
      if (track.id == trackId) {
        if (track.handle != null &&
            SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
          SoLoud.instance.setPan(track.handle!, clampedPan);
        }
        return track.copyWith(pan: clampedPan);
      }
      return track;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
  }

  void recalculateAllAudioOutputs() {
    for (var track in state.tracks) {
      applyAudioOutputForTrack(track);
    }
  }

  void applyAudioOutputForTrack(SoLoudTrackModel track) {
    if (track.handle == null ||
        track.handle!.id == 0 ||
        !SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
      return;
    }

    final hasActiveSolo = state.tracks.any((t) => t.isSolo);
    double targetVolume = 0.0;

    if (hasActiveSolo) {
      targetVolume = track.isSolo ? (track.volume * state.masterVolume) : 0.0;
    } else {
      targetVolume = track.isMuted ? 0.0 : (track.volume * state.masterVolume);
    }

    SoLoud.instance.setVolume(track.handle!, targetVolume);
  }

  Future<void> disposeAllTracks() async {
    for (var track in state.tracks) {
      if (track.handle != null &&
          track.handle!.id != 0 &&
          SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
        await SoLoud.instance.stop(track.handle!);
      }
      await SoLoud.instance.disposeSource(track.soundSource);
    }
    state = const TracksMixerState();
  }

  void setLoadedTracks(List<SoLoudTrackModel> tracks, double masterVolume) {
    state = state.copyWith(tracks: tracks, masterVolume: masterVolume);
  }

  void setLoading(bool loading, [String status = '', double progress = 0.0]) {
    state = state.copyWith(
      isLoading: loading,
      loadingStatus: status,
      loadingProgress: progress,
    );
  }

  Future<void> removeAllTracks() async {
    // 1. Liberar la memoria y detener la reproducción de SoLoud
    await disposeAllTracks();

    // 2. Resetear la duración en el proveedor de reproducción
    ref.read(playbackProvider.notifier).resetPlayback();
  }
}

final tracksMixerProvider =
    NotifierProvider<TracksMixerNotifier, TracksMixerState>(
      TracksMixerNotifier.new,
    );
