import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:multitracks/config/app_config.dart';
import 'package:multitracks/data/soloud_track_model.dart';
import 'package:multitracks/services/hive_service.dart';

class SoLoudSessionState {
  final String sessionId;
  final String title;
  final String keyNote;
  final int bpm;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<SoLoudTrackModel> tracks;
  final double masterVolume;
  final bool isLoading;
  final String loadingStatus; // <--- AGREGAR
  final double loadingProgress; // <--- AGREGAR

  SoLoudSessionState({
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
    this.loadingStatus = '', // <--- AGREGAR
    this.loadingProgress = 0.0, // <--- AGREGAR
  });

  // Getter de progreso
  double get progress => duration.inMilliseconds == 0
      ? 0.0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  SoLoudSessionState copyWith({
    String? sessionId,
    String? title,
    String? keyNote,
    int? bpm,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<SoLoudTrackModel>? tracks,
    double? masterVolume,
    bool? isLoading,
    String? loadingStatus, // <--- AGREGAR AL COPYWITH
    double? loadingProgress, // <--- AGREGAR AL COPYWITH
  }) {
    return SoLoudSessionState(
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
      loadingStatus: loadingStatus ?? this.loadingStatus,
      loadingProgress: loadingProgress ?? this.loadingProgress,
    );
  }
}

class SoLoudSessionNotifier extends Notifier<SoLoudSessionState> {
  Timer? _positionTimer;

  @override
  SoLoudSessionState build() {
    _initEngine();

    ref.onDispose(() {
      _positionTimer?.cancel();
      _disposeAllTracks();
    });

    return SoLoudSessionState();
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
    // 1. OBTENER RUTAS EXISTENTES EN EL ESTADO
    final existingPaths = state.tracks.map((t) => t.filePath).toSet();

    // 2. FILTRAR SOLO LOS ARCHIVOS NUEVOS (NO CARGADOS PREVIAMENTE)
    final newFiles = result.files.where((file) {
      return file.path != null && !existingPaths.contains(file.path);
    }).toList();

    // Si todos los archivos seleccionados ya estaban cargados, salimos
    if (newFiles.isEmpty) {
      debugPrint("Todos los archivos seleccionados ya están cargados.");
      return;
    }
    // 1. Iniciar estado con status y progress iniciales
    state = state.copyWith(
      isLoading: true,
      loadingStatus: 'Iniciando carga...',
      loadingProgress: 0.0,
    );

    final List<SoLoudTrackModel> newTracks = [];
    Duration maxDuration = state.duration;

    try {
      final totalFiles = result.files.length;

      for (int i = 0; i < totalFiles; i++) {
        final file = result.files[i];
        if (file.path == null) continue;

        final filePath = file.path!;
        final fullName = file.name; // Ej: "Piano.mp3"
        final fileName = fullName.replaceAll(
          RegExp(r'\.[^.]+$'),
          '',
        ); // Ej: "Piano"

        // 2. ACTUALIZAR ESTADO EN CADA ITERACIÓN
        final progress = (i + 1) / totalFiles;
        state = state.copyWith(
          loadingStatus: 'Cargando $fullName (${i + 1}/$totalFiles)...',
          loadingProgress: progress,
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
          debugPrint(
            "Error cargando archivo individual ($fileName): $fileError",
          );
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (newTracks.isNotEmpty) {
        state = state.copyWith(
          tracks: [...state.tracks, ...newTracks],
          duration: maxDuration,
        );
      }
    } catch (e) {
      debugPrint("Error general en el proceso de carga: $e");
      for (var track in newTracks) {
        await SoLoud.instance.disposeSource(track.soundSource);
      }
    } finally {
      // 3. LIMPIAR ESTADO AL FINALIZAR
      state = state.copyWith(
        isLoading: false,
        loadingStatus: '',
        loadingProgress: 0.0,
      );
    }
  }

  // Cargar sesión desde Hive
  Future<void> loadSessionFromMap(Map<String, dynamic> sessionData) async {
    _positionTimer?.cancel();

    // 1. Reiniciar el motor SoLoud en C++ para limpiar memoria/handles colgados (Hot Restart Fix)
    try {
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.deinit();
      }
      await SoLoud.instance.init();
    } catch (e) {
      debugPrint("Error al reinicializar el motor SoLoud: $e");
    }

    // 2. Limpiar pistas anteriores si quedaba alguna en memoria
    await _disposeAllTracks();

    state = SoLoudSessionState(isLoading: true);

    List<SoLoudTrackModel> loadedTracks = [];
    Duration maxDuration = Duration.zero;

    final rawTracks = sessionData['tracks'] as List<dynamic>? ?? [];
    final totalFiles = rawTracks.length;

    for (int i = 0; i < rawTracks.length; i++) {
      final trackMap = rawTracks[i];
      final map = Map<String, dynamic>.from(trackMap);
      final filePath = map['filePath'] as String?;

      if (filePath == null || filePath.isEmpty) continue;

      final fileName = filePath.split('/').last;

      // Actualizar progreso durante la carga desde Hive
      state = state.copyWith(
        loadingStatus: 'Cargando $fileName (${i + 1}/$totalFiles)...',
        loadingProgress: totalFiles > 0 ? (i + 1) / totalFiles : 0.0,
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
        debugPrint("Error cargando fuente en SoLoud ($filePath): $e");
      }
    }

    state = state.copyWith(
      sessionId: sessionData['id'] as String? ?? '',
      title: sessionData['title'] as String? ?? '',
      keyNote: sessionData['keyNote'] as String? ?? 'C / DO',
      bpm: (sessionData['bpm'] as num?)?.toInt() ?? 120,
      tracks: List<SoLoudTrackModel>.from(loadedTracks),
      duration: maxDuration,
      position: Duration.zero,
      masterVolume: (sessionData['masterVolume'] as num?)?.toDouble() ?? 1.0,
      isLoading: false,
      loadingStatus: '',
      loadingProgress: 0.0,
    );
  }

  // Play / Pause Sincronizado
  Future<void> togglePlay() async {
    if (state.tracks.isEmpty) return;

    if (state.isPlaying) {
      // 1. PAUSAR TODAS LAS PISTAS
      for (var track in state.tracks) {
        if (track.handle != null &&
            track.handle!.id != 0 &&
            SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
          SoLoud.instance.setPause(track.handle!, true);
        }
      }
      _positionTimer?.cancel();
      state = state.copyWith(isPlaying: false);
    } else {
      // 2. OBTENER / GENERAR HANDLES PARA CADA PISTA
      final List<SoLoudTrackModel> updatedTracks = [];

      for (var track in state.tracks) {
        SoundHandle? h = track.handle;

        // Si el handle no existe o venció, asignamos una nueva voz pausada
        if (h == null ||
            h.id == 0 ||
            !SoLoud.instance.getIsValidVoiceHandle(h)) {
          h = await SoLoud.instance.play(track.soundSource, paused: true);
        }

        updatedTracks.add(track.copyWith(handle: h));
      }

      // Actualizamos el estado con los nuevos handles
      state = state.copyWith(tracks: updatedTracks);

      // Margen para que el buffer de streaming lea desde disco
      await Future.delayed(const Duration(milliseconds: 40));

      final currentPos = state.position;

      // 3. ACTIVAR Y PROTEGER CADA UNA DE LAS VOCES
      for (var track in state.tracks) {
        final handle = track.handle;

        if (handle != null &&
            handle.id != 0 &&
            SoLoud.instance.getIsValidVoiceHandle(handle)) {
          // Marca el canal como protegido para que C++ no lo apague
          SoLoud.instance.setProtectVoice(handle, true);

          // Sincronizar tiempo
          SoLoud.instance.seek(handle, currentPos);

          // --- APLICAR PANNING L/R (-1.0 a 1.0) ---
          SoLoud.instance.setPan(handle, track.pan);

          // Aplicar volumen individual/master
          _applyAudioOutput(track);

          // Iniciar reproducción de la voz
          SoLoud.instance.setPause(handle, false);
        }
      }

      _startPositionTimer();
      state = state.copyWith(isPlaying: true);
    }
  }

  // Stop / Rewind
  Future<void> stop() async {
    _positionTimer?.cancel();
    for (var track in state.tracks) {
      if (track.handle != null &&
          track.handle!.id != 0 &&
          SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
        SoLoud.instance.seek(track.handle!, Duration.zero);
        SoLoud.instance.setPause(track.handle!, true);
      }
    }
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  // Seek preciso y seguro
  Future<void> seekTo(double progressNormalized) async {
    if (state.tracks.isEmpty) return;

    final targetMs = (state.duration.inMilliseconds * progressNormalized)
        .toInt();
    final targetDuration = Duration(milliseconds: targetMs);

    for (var track in state.tracks) {
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

  // Control de Volumen y Mute/Solo
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

  void setMasterVolume(double volume) {
    state = state.copyWith(masterVolume: volume);
    _recalculateAllAudioOutputs();
  }

  void _recalculateAllAudioOutputs() {
    for (var track in state.tracks) {
      _applyAudioOutput(track);
    }
  }

  void _applyAudioOutput(SoLoudTrackModel track) {
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

  // Timer optimizado a 16ms (~60FPS) para animación fluida de la onda
  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (state.tracks.isNotEmpty) {
        final activeTrack = state.tracks.firstWhere(
          (t) =>
              t.handle != null &&
              t.handle!.id != 0 &&
              SoLoud.instance.getIsValidVoiceHandle(t.handle!),
          orElse: () => state.tracks.first,
        );

        if (activeTrack.handle != null && activeTrack.handle!.id != 0) {
          final currentPos = SoLoud.instance.getPosition(activeTrack.handle!);

          // Si llega al final del audio, pausar automáticamente
          if (currentPos >= state.duration && state.duration > Duration.zero) {
            stop();
          } else {
            state = state.copyWith(position: currentPos);
          }
        }
      }
    });
  }

  void updateMetadata({String? title, String? keyNote, int? bpm}) {
    state = state.copyWith(
      title: title ?? state.title,
      keyNote: keyNote ?? state.keyNote,
      bpm: bpm ?? state.bpm,
    );
  }

  Future<void> removeAllTracks() async {
    _positionTimer?.cancel();
    await _disposeAllTracks();
    state = state.copyWith(
      tracks: [],
      duration: Duration.zero,
      position: Duration.zero,
      isPlaying: false,
    );
  }

  Future<void> resetSession() async {
    // 1. Liberar las fuentes C++ de la sesión (disposeSource detiene el audio automáticamente)
    for (final track in state.tracks) {
      try {
        await SoLoud.instance.disposeSource(track.soundSource);
      } catch (e) {
        debugPrint("Error liberando fuente: $e");
      }
    }

    // Opcional: Para limpiar de golpe todo el motor de sonido si no usas el loop individual
    // await SoLoud.instance.disposeAllSound();

    // 2. Reiniciar el estado de Riverpod
    state = SoLoudSessionState();
  }

  Future<void> _disposeAllTracks() async {
    for (var track in state.tracks) {
      if (track.handle != null &&
          track.handle!.id != 0 &&
          SoLoud.instance.getIsValidVoiceHandle(track.handle!)) {
        await SoLoud.instance.stop(track.handle!);
      }
      await SoLoud.instance.disposeSource(track.soundSource);
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

      await HiveService.saveSession(sessionMap);
      return true;
    } catch (e) {
      debugPrint("Error guardando sesión: $e");
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void setTrackPan(String trackId, double panValue) {
    final clampedPan = panValue.clamp(-1.0, 1.0);

    final updatedTracks = state.tracks.map((track) {
      if (track.id == trackId) {
        // Si la pista se está reproduciendo actualmente, aplicamos el pan a SoLoud
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
}

final soLoudSessionProvider =
    NotifierProvider<SoLoudSessionNotifier, SoLoudSessionState>(() {
      return SoLoudSessionNotifier();
    });
