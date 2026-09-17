import 'package:multitracks/data/track_model.dart';

class SessionState {
  final String sessionId;
  final String title;
  final String keyNote;
  final int bpm;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<TrackModel> tracks;
  final double masterVolume;
  final bool isLoading;

  SessionState({
    this.sessionId = '',
    this.title = '',
    this.keyNote = 'C / DO',
    this.bpm = 120,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.tracks = const [],
    this.masterVolume = 1.0,
    this.isLoading = false,
  });

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    final calc = position.inMilliseconds / duration.inMilliseconds;
    return calc.clamp(0.0, 1.0);
  }

  SessionState copyWith({
    String? sessionId,
    String? title,
    String? keyNote,
    int? bpm,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<TrackModel>? tracks,
    double? masterVolume,
    bool? isLoading,
  }) {
    return SessionState(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      keyNote: keyNote ?? this.keyNote,
      bpm: bpm ?? this.bpm,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      tracks: tracks ?? this.tracks,
      masterVolume: masterVolume ?? this.masterVolume,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
