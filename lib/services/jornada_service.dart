import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import '../models/jornada.dart';

class JornadaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================
  // INICIAR UNA JORNADA
  // ============================================
  Future<String> iniciarJornada(String usuarioId) async {
    try {
      final docRef = await _db.collection('jornadas').add({
        'usuarioId': usuarioId,
        'horaInicio': Timestamp.now(),
        'horaFin': null,
        'estado': 'activa',
      });
      return docRef.id; // Devolvemos el ID del documento creado
    } catch (e) {
      debugPrint('Error al iniciar jornada: $e');
      rethrow;
    }
  }

  // ============================================
  // FINALIZAR UNA JORNADA
  // ============================================
  Future<void> finalizarJornada(String jornadaId) async {
    try {
      await _db.collection('jornadas').doc(jornadaId).update({
        'horaFin': Timestamp.now(),
        'estado': 'finalizada',
      });
    } catch (e) {
      debugPrint('Error al finalizar jornada: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER LA JORNADA ACTIVA DEL USUARIO
  // ============================================
  Future<Jornada?> obtenerJornadaActiva(String usuarioId) async {
    try {
      final query = await _db
          .collection('jornadas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('estado', isEqualTo: 'activa')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null; // No hay jornada activa
      }

      final doc = query.docs.first;
      return Jornada.fromMap(doc.id, doc.data());
    } catch (e) {
      debugPrint('Error al obtener jornada activa: $e');
      rethrow;
    }
  }
}
