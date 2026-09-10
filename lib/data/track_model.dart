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
}
