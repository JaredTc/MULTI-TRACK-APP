import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'tracks_mixer_provider.dart';

class PlaybackState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const PlaybackState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  double get progress => duration.inMilliseconds == 0
      ? 0.0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  PlaybackState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlaybackNotifier extends Notifier<PlaybackState> {
  Timer? _positionTimer;

  @override
  PlaybackState build() {
    ref.onDispose(() => _positionTimer?.cancel());
    return const PlaybackState();
  }

  void updateDuration(Duration maxDuration) {
    state = state.copyWith(duration: maxDuration);
  }

  Future<void> togglePlay() async {
    final mixerState = ref.read(tracksMixerProvider);
    final tracks = mixerState.tracks;

    if (tracks.isEmpty) return;

    if (state.isPlaying) {
      for (var track in tracks) {
        if (track.handle != null &&
            track.handle!.id != 0 &&
            SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
          SoLoud.instance.setPause(track.handle!, true);
        }
      }
      _positionTimer?.cancel();
      state = state.copyWith(isPlaying: false);
    } else {
      final updatedTracks = await ref
          .read(tracksMixerProvider.notifier)
          .ensureVoiceHandles();

      await Future.delayed(const Duration(milliseconds: 40));
      final currentPos = state.position;

      for (var track in updatedTracks) {
        final handle = track.handle;
        if (handle != null &&
            handle.id != 0 &&
            SoLoud.instance.getIsValidVoiceHandle(handle)) {
          SoLoud.instance.setProtectVoice(handle, true);
          SoLoud.instance.seek(handle, currentPos);
          SoLoud.instance.setPan(handle, track.pan);

          ref
              .read(tracksMixerProvider.notifier)
              .applyAudioOutputForTrack(track);

          SoLoud.instance.setPause(handle, false);
        }
      }

      _startPositionTimer();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> stop() async {
    _positionTimer?.cancel();
    final tracks = ref.read(tracksMixerProvider).tracks;

    for (var track in tracks) {
      if (track.handle != null &&
          track.handle!.id != 0 &&
          SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
        SoLoud.instance.seek(track.handle!, Duration.zero);
        SoLoud.instance.setPause(track.handle!, true);
      }
    }
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  Future<void> seekTo(double progressNormalized) async {
    final tracks = ref.read(tracksMixerProvider).tracks;
    if (tracks.isEmpty) return;

    final targetMs = (state.duration.inMilliseconds * progressNormalized)
        .toInt();
    final targetDuration = Duration(milliseconds: targetMs);

    for (var track in tracks) {
      final handle = track.handle;
      if (handle != null &&
          handle.id != 0 &&
          SoLoud.instance.getIsValidVoiceHandle(handle)) {
        try {
          SoLoud.instance.seek(handle, targetDuration);
        } catch (e) {
          debugPrint("Error haciendo seek en la pista ${track.title}: $e");
        }
      }
    }

    state = state.copyWith(position: targetDuration);
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final tracks = ref.read(tracksMixerProvider).tracks;
      if (tracks.isNotEmpty) {
        final activeTrack = tracks.firstWhere(
          (t) =>
              t.handle != null &&
              t.handle!.id != 0 &&
              SoLoud.instance.getIsValidVoiceHandle(t.handle!),
          orElse: () => tracks.first,
        );

        if (activeTrack.handle != null && activeTrack.handle!.id != 0) {
          final currentPos = SoLoud.instance.getPosition(activeTrack.handle!);

          if (currentPos >= state.duration && state.duration > Duration.zero) {
            stop();
          } else {
            state = state.copyWith(position: currentPos);
          }
        }
      }
    });
  }

  void resetPlayback() {
    _positionTimer?.cancel();
    state = const PlaybackState();
  }
}

final playbackProvider = NotifierProvider<PlaybackNotifier, PlaybackState>(
  PlaybackNotifier.new,
);
