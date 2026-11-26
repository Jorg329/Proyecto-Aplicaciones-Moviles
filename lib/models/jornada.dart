import 'package:cloud_firestore/cloud_firestore.dart';

class Jornada {
  final String id;
  final String usuarioId;
  final DateTime horaInicio;
  final DateTime? horaFin;
  final String estado; // 'activa' o 'finalizada'

  Jornada({
    required this.id,
    required this.usuarioId,
    required this.horaInicio,
    this.horaFin,
    required this.estado,
  });

  // ============================================
  // CONVERTIR DE FIRESTORE A JORNADA
  // ============================================
  factory Jornada.fromMap(String id, Map<String, dynamic> map) {
    return Jornada(
      id: id,
      usuarioId: map['usuarioId'] ?? '',
      horaInicio: (map['horaInicio'] as Timestamp).toDate(),
      horaFin: map['horaFin'] != null
          ? (map['horaFin'] as Timestamp).toDate()
          : null,
      estado: map['estado'] ?? 'activa',
    );
  }

  // ============================================
  // CONVERTIR DE JORNADA A FIRESTORE
  // ============================================
  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'horaInicio': Timestamp.fromDate(horaInicio),
      'horaFin': horaFin != null ? Timestamp.fromDate(horaFin!) : null,
      'estado': estado,
    };
  }

  // ============================================
  // COPIAR CON CAMBIOS (útil para actualizar)
  // ============================================
  Jornada copyWith({
    String? id,
    String? usuarioId,
    DateTime? horaInicio,
    DateTime? horaFin,
    String? estado,
  }) {
    return Jornada(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      estado: estado ?? this.estado,
    );
  }
}
