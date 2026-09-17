import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class SoLoudTrackModel {
  final String id;
  final String title;
  final Color color;
  final String filePath;
  final AudioSource soundSource;
  final SoundHandle? handle;
  final double volume;
  final double pan; // <-- AÑADIDO: Panning (-1.0 Izq, 1.0 Der)
  final bool isMuted;
  final bool isSolo;
  // En tu SessionMetadataState
  final String? coverImagePath;

  SoLoudTrackModel({
    required this.id,
    required this.title,
    required this.color,
    required this.filePath,
    required this.soundSource,
    this.handle,
    this.volume = 1.0,
    this.pan = 0.0, // <-- Default al Centro
    this.isMuted = false,
    this.isSolo = false,
    this.coverImagePath,
  });

  SoLoudTrackModel copyWith({
    String? id,
    String? title,
    Color? color,
    String? filePath,
    AudioSource? soundSource,
    SoundHandle? handle,
    double? volume,
    double? pan,
    bool? isMuted,
    bool? isSolo,
    String? coverImagePath,
  }) {
    return SoLoudTrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      filePath: filePath ?? this.filePath,
      soundSource: soundSource ?? this.soundSource,
      handle: handle ?? this.handle,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }

  factory SoLoudTrackModel.fromMap(
    Map<String, dynamic> map,
    AudioSource soundSource,
  ) {
    return SoLoudTrackModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      color: Color(map['color'] as int? ?? 0xFF0088FF),
      filePath: map['filePath'] as String? ?? '',
      soundSource: soundSource,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      pan: (map['pan'] as num?)?.toDouble() ?? 0.0, // <-- Cargar de Hive
      isMuted: map['isMuted'] as bool? ?? false,
      isSolo: map['isSolo'] as bool? ?? false,
      coverImagePath: map['coverImagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color.value,
      'filePath': filePath,
      'volume': volume,
      'pan': pan, // <-- Guardar en Hive
      'isMuted': isMuted,
      'isSolo': isSolo,
      'coverImagePath': coverImagePath,
    };
  }
}
