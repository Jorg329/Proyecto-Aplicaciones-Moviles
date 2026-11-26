import 'package:cloud_firestore/cloud_firestore.dart';

class Tarea {
  final String id;
  final String titulo;
  final String descripcion;
  final String cliente;
  final String direccion;
  final DateTime horaProgramada;
  final String estado; // 'pendiente', 'en_progreso', 'completada'
  final int progreso; // 0 a 100
  final String usuarioId;
  final double? latitud;
  final double? longitud;

  Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.direccion,
    required this.horaProgramada,
    required this.estado,
    required this.progreso,
    required this.usuarioId,
    this.latitud,
    this.longitud,
  });

  // ============================================
  // CONVERTIR DE FIRESTORE A TAREA
  // ============================================
  factory Tarea.fromMap(String id, Map<String, dynamic> map) {
    return Tarea(
      id: id,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      cliente: map['cliente'] ?? '',
      direccion: map['direccion'] ?? '',
      horaProgramada: (map['horaProgramada'] as Timestamp).toDate(),
      estado: map['estado'] ?? 'pendiente',
      progreso: map['progreso'] ?? 0,
      usuarioId: map['usuarioId'] ?? '',
      latitud: map['latitud']?.toDouble(),
      longitud: map['longitud']?.toDouble(),
    );
  }

  // ============================================
  // CONVERTIR DE TAREA A FIRESTORE
  // ============================================
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'direccion': direccion,
      'horaProgramada': Timestamp.fromDate(horaProgramada),
      'estado': estado,
      'progreso': progreso,
      'usuarioId': usuarioId,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  // ============================================
  // COPIAR CON CAMBIOS
  // ============================================
  Tarea copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? cliente,
    String? direccion,
    DateTime? horaProgramada,
    String? estado,
    int? progreso,
    String? usuarioId,
    double? latitud,
    double? longitud,
  }) {
    return Tarea(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      cliente: cliente ?? this.cliente,
      direccion: direccion ?? this.direccion,
      horaProgramada: horaProgramada ?? this.horaProgramada,
      estado: estado ?? this.estado,
      progreso: progreso ?? this.progreso,
      usuarioId: usuarioId ?? this.usuarioId,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
    );
  }
}
