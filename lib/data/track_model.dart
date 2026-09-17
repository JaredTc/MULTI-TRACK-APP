import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class TrackModel {
  final String id;
  final String title;
  final Color color;
  final String filePath;
  final AudioPlayer player;
  final double volume;
  final bool isMuted;
  final bool isSolo;

  TrackModel({
    required this.id,
    required this.title,
    required this.color,
    required this.filePath,
    required this.player,
    this.volume = 0.7,
    this.isMuted = false,
    this.isSolo = false,
  });

  TrackModel copyWith({
    String? id,
    String? title,
    Color? color,
    String? filePath,
    AudioPlayer? player,
    double? volume,
    bool? isMuted,
    bool? isSolo,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      filePath: filePath ?? this.filePath,
      player: player ?? this.player,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
    );
  }

  // 1. Convertir el modelo a un Map (para guardarlo en Hive)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color.value, // Guarda el color como entero (ARGB)
      'filePath': filePath,
      'volume': volume,
      'isMuted': isMuted,
      'isSolo': isSolo,
    };
  }

  // 2. Reconstruir el modelo desde un Map (al cargar de Hive)
  // Requiere pasar la instancia de AudioPlayer ya inicializada
  factory TrackModel.fromMap(Map<String, dynamic> map, AudioPlayer player) {
    return TrackModel(
      id: map['id'] as String,
      title: map['title'] as String,
      color: Color(map['color'] as int),
      filePath: map['filePath'] as String,
      volume: (map['volume'] as num?)?.toDouble() ?? 0.7,
      isMuted: map['isMuted'] as bool? ?? false,
      isSolo: map['isSolo'] as bool? ?? false,
      player: player,
    );
  }
}
